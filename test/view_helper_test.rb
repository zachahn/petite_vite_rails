require "test_helper"
require "tmpdir"
require "minitest/mock"

class PetiteViteViewHelperTest < ActionView::TestCase
  include PetiteVite::ViewHelper

  setup do
    @tmpdir = Dir.mktmpdir
    @manifest_path = File.join(@tmpdir, "manifest.json")
    File.write(@manifest_path, JSON.dump({
      "src/main.ts" => {
        "file" => "assets/main-abc123.js",
        "css" => ["assets/main-abc123.css"],
        "dynamicImports" => ["src/lazy.ts"],
        "isEntry" => true
      },
      "src/lazy.ts" => {
        "file" => "assets/lazy-def456.js",
        "css" => ["assets/lazy-def456.css"]
      },
      "src/_internal.ts" => {
        "file" => "assets/internal-xxx.js"
      }
    }))

    config_path = File.join(@tmpdir, "petite_vite.json")
    File.write(config_path, JSON.dump({
      "buildCommand" => "yarn build",
      "entrypointOutput" => "/src/main.js",
      "frontendRoot" => "frontend"
    }))

    @previous_manifest = defined?(VITE_MANIFEST) ? VITE_MANIFEST : nil
    @previous_config = defined?(VITE_CONFIG) ? VITE_CONFIG : nil
    Object.send(:remove_const, :VITE_MANIFEST) if defined?(VITE_MANIFEST)
    Object.send(:remove_const, :VITE_CONFIG) if defined?(VITE_CONFIG)
    Object.const_set(:VITE_CONFIG, PetiteVite::Config.new(config_path))
    Object.const_set(:VITE_MANIFEST, PetiteVite::Manifest.new(config: VITE_CONFIG, manifest_path: @manifest_path))
  end

  teardown do
    Object.send(:remove_const, :VITE_MANIFEST) if defined?(VITE_MANIFEST)
    Object.send(:remove_const, :VITE_CONFIG) if defined?(VITE_CONFIG)
    Object.const_set(:VITE_MANIFEST, @previous_manifest) if @previous_manifest
    Object.const_set(:VITE_CONFIG, @previous_config) if @previous_config
    FileUtils.remove_entry(@tmpdir)
  end

  test "vite_tags in development emits the vite client and the entrypoint output" do
    Rails.env.stub(:development?, true) do
      tag = vite_tags

      assert tag.html_safe?
      assert_includes tag, %q(<script type="module" src="http://localhost:5173/@vite/client"></script>)
      assert_includes tag, %q(<script type="module" src="http://localhost:5173/src/main.js"></script>)
    end
  end

  test "vite_tags in production emits stylesheets, module script, and modulepreloads for entries" do
    Rails.env.stub(:development?, false) do
      tag = vite_tags

      assert tag.html_safe?
      assert_includes tag, %q(<link rel="stylesheet" href="/assets/main-abc123.css" />)
      assert_includes tag, %q(<link rel="stylesheet" href="/assets/lazy-def456.css" />)
      assert_includes tag, %q(<script type="module" src="/assets/main-abc123.js"></script>)
      assert_includes tag, %q(<link rel="modulepreload" href="/assets/lazy-def456.js" />)
    end
  end

  test "vite_tags in production skips non-entry chunks" do
    Rails.env.stub(:development?, false) do
      tag = vite_tags

      refute_includes tag, "assets/internal-xxx.js"
    end
  end
end

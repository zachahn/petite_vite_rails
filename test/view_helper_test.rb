require "test_helper"
require "tmpdir"
require "minitest/mock"

class PetiteViteViewHelperTest < ActionView::TestCase
  include PetiteVite::ViewHelper

  setup do
    @tmpdir = Dir.mktmpdir
    frontend_root = File.join(@tmpdir, "frontend")
    vite_manifest_relpath = "manifest.json"
    FileUtils.mkdir_p(frontend_root)
    File.write(File.join(frontend_root, vite_manifest_relpath), JSON.dump({
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

    shared_json_path = File.join(@tmpdir, "petite_vite.json")
    File.write(shared_json_path, JSON.dump({
      "buildCommand" => "yarn build",
      "entrypointOutput" => "/src/main.js",
      "frontendRoot" => frontend_root
    }))

    @previous_config = PetiteVite.config
    PetiteVite.config = PetiteVite::Config.new(shared_json_path: shared_json_path, vite_manifest_relpath: vite_manifest_relpath)
  end

  teardown do
    PetiteVite.config = @previous_config
    FileUtils.remove_entry(@tmpdir)
  end

  def test_vite_tags_in_development_emits_the_vite_client_and_the_entrypoint_output
    Rails.env.stub(:development?, true) do
      tag = vite_tags

      assert tag.html_safe?
      assert_includes tag, %q(<script type="module" src="http://localhost:5173/@vite/client"></script>)
      assert_includes tag, %q(<script type="module" src="http://localhost:5173/src/main.js"></script>)
    end
  end

  def test_vite_tags_in_production_emits_stylesheets_module_script_and_modulepreloads_for_entries
    Rails.env.stub(:development?, false) do
      tag = vite_tags

      assert tag.html_safe?
      assert_includes tag, %q(<link rel="stylesheet" href="/assets/main-abc123.css" />)
      assert_includes tag, %q(<link rel="stylesheet" href="/assets/lazy-def456.css" />)
      assert_includes tag, %q(<script type="module" src="/assets/main-abc123.js"></script>)
      assert_includes tag, %q(<link rel="modulepreload" href="/assets/lazy-def456.js" />)
    end
  end

  def test_vite_tags_in_production_skips_non_entry_chunks
    Rails.env.stub(:development?, false) do
      tag = vite_tags

      refute_includes tag, "assets/internal-xxx.js"
    end
  end
end

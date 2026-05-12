require "test_helper"
require "json"
require "rails/generators/test_case"
require "generators/petite_vite/install/install_generator"

class PetiteVite::InstallGeneratorTest < Rails::Generators::TestCase
  tests PetiteVite::InstallGenerator
  destination File.expand_path("../tmp/install_generator", __dir__)
  setup :prepare_destination
  setup :seed_frontend_stub

  def test_inserts_vite_tags_into_application_layout
    layout_path = File.join(destination_root, "app/views/layouts/application.html.erb")
    FileUtils.mkdir_p(File.dirname(layout_path))
    File.write(layout_path, <<~ERB)
      <!DOCTYPE html>
      <html>
        <head>
          <title>Dummy</title>
        </head>
        <body></body>
      </html>
    ERB

    run_generator

    assert_includes File.read(layout_path), "<%= vite_tags %>"
  end

  def test_skips_the_mailer_layout
    mailer_layout_path = File.join(destination_root, "app/views/layouts/mailer.html.erb")
    FileUtils.mkdir_p(File.dirname(mailer_layout_path))
    original = "<html><head></head><body></body></html>"
    File.write(mailer_layout_path, original)

    run_generator

    assert_equal original, File.read(mailer_layout_path)
  end

  def test_creates_initializer_and_shared_config
    run_generator

    assert_file "config/initializers/petite_vite.rb"
    assert_file "config/petite_vite.json" do |contents|
      shared = JSON.parse(contents)
      %w[buildCommand entrypointInput entrypointOutput frontendRoot localServerCorsOrigin].each do |key|
        assert shared.key?(key), "expected petite_vite.json to have key #{key.inspect}"
      end
    end
  end

  def test_creates_root_package_json
    run_generator

    assert_file "package.json"
  end

  def test_creates_procfile_dev_with_web_and_vite_lines
    run_generator

    assert_file "Procfile.dev" do |contents|
      assert_match(/^web:/, contents)
      assert_match(/^vite:/, contents)
    end
  end

  def test_creates_executable_bin_dev
    run_generator

    bin_dev = File.join(destination_root, "bin/dev")
    assert_file "bin/dev"
    assert File.executable?(bin_dev), "expected bin/dev to be executable"
  end

  def test_injects_shared_cors_origin_into_vite_config
    run_generator

    assert_file "frontend/vite.config.ts" do |contents|
      assert_includes contents, "shared.localServerCorsOrigin"
    end
  end

  private

  def seed_frontend_stub
    frontend = File.join(destination_root, "frontend")
    FileUtils.mkdir_p(File.join(frontend, "src"))
    File.write(File.join(frontend, "package.json"), %({"name":"frontend","private":true}))
    File.write(File.join(frontend, "src/main.ts"), "")
    File.write(File.join(frontend, "vite.config.ts"), <<~TS)
      import { defineConfig } from 'vite'

      export default defineConfig({
        plugins: [],
      })
    TS
  end
end

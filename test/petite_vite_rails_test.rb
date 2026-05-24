require "test_helper"
require "tmpdir"

class PetiteViteRailsTest < ActiveSupport::TestCase
  def test_it_has_version_number
    assert_kind_of String, PetiteViteRails::VERSION
  end

  def test_config_reads_shared_json
    Dir.mktmpdir do |tmpdir|
      shared_json_path = File.join(tmpdir, "petite_vite.json")
      File.write(shared_json_path, JSON.dump({
        "buildCommand" => "yarn build",
        "frontendOutput" => "/src/main.js",
        "frontendRoot" => "frontend"
      }))

      config = PetiteVite::Config.new(
        shared_json_path: shared_json_path,
        vite_manifest_relpath: "dist/.vite/manifest.json"
      )

      assert_equal "yarn build", config.build_command
      assert_equal "/src/main.js", config.frontend_output
      assert_equal "frontend", config.frontend_root
      assert_equal "frontend/dist/.vite/manifest.json", config.manifest_path
    end
  end

  def test_manifest_reads_from_disk_when_present
    Dir.mktmpdir do |tmpdir|
      frontend_root = File.join(tmpdir, "frontend")
      FileUtils.mkdir_p(frontend_root)
      File.write(File.join(frontend_root, "manifest.json"), JSON.dump({
        "src/main.ts" => {"file" => "assets/main.js", "isEntry" => true}
      }))

      shared_json_path = File.join(tmpdir, "petite_vite.json")
      File.write(shared_json_path, JSON.dump({
        "buildCommand" => "yarn build",
        "frontendOutput" => "/src/main.js",
        "frontendRoot" => frontend_root
      }))

      config = PetiteVite::Config.new(
        shared_json_path: shared_json_path,
        vite_manifest_relpath: "manifest.json"
      )

      assert_equal "assets/main.js", config.manifest.contents.dig("src/main.ts", "file")
    end
  end

  def test_vite_dev_server_port_defaults_to_5173_when_absent
    Dir.mktmpdir do |tmpdir|
      shared_json_path = File.join(tmpdir, "petite_vite.json")
      File.write(shared_json_path, JSON.dump({"frontendRoot" => "frontend"}))

      config = PetiteVite::Config.new(shared_json_path: shared_json_path, vite_manifest_relpath: "manifest.json")

      assert_equal 5173, config.vite_dev_server_port
    end
  end

  def test_vite_dev_server_port_reads_value_when_present
    Dir.mktmpdir do |tmpdir|
      shared_json_path = File.join(tmpdir, "petite_vite.json")
      File.write(shared_json_path, JSON.dump({"frontendRoot" => "frontend", "viteDevServerPort" => 6000}))

      config = PetiteVite::Config.new(shared_json_path: shared_json_path, vite_manifest_relpath: "manifest.json")

      assert_equal 6000, config.vite_dev_server_port
    end
  end

  def test_vite_dev_server_port_raises_when_not_an_integer
    Dir.mktmpdir do |tmpdir|
      shared_json_path = File.join(tmpdir, "petite_vite.json")
      File.write(shared_json_path, JSON.dump({"frontendRoot" => "frontend", "viteDevServerPort" => "5173"}))

      config = PetiteVite::Config.new(shared_json_path: shared_json_path, vite_manifest_relpath: "manifest.json")

      error = assert_raises(RuntimeError) { config.vite_dev_server_port }
      assert_match(/viteDevServerPort/, error.message)
      assert_match(/Integer/, error.message)
    end
  end

  def test_manifest_is_empty_when_file_missing
    Dir.mktmpdir do |tmpdir|
      shared_json_path = File.join(tmpdir, "petite_vite.json")
      File.write(shared_json_path, JSON.dump({
        "buildCommand" => "yarn build",
        "frontendOutput" => "/src/main.js",
        "frontendRoot" => File.join(tmpdir, "frontend")
      }))

      config = PetiteVite::Config.new(
        shared_json_path: shared_json_path,
        vite_manifest_relpath: "manifest.json"
      )

      assert_equal({}, config.manifest.contents)
    end
  end
end

require_relative "petite_vite_rails/version"
require_relative "petite_vite_rails/view_helper"
require_relative "petite_vite_rails/railtie"

module PetiteVite
  class << self
    attr_accessor :config
  end

  class Config
    DEFAULT_VITE_DEV_SERVER_PORT = 5173

    def initialize(shared_json_path:, vite_manifest_relpath:)
      @shared_json_path = shared_json_path
      @contents = JSON.parse(File.read(shared_json_path))
      @vite_manifest_relpath = vite_manifest_relpath
    end

    def build_command = @contents.fetch("buildCommand")

    def frontend_output = @contents.fetch("frontendOutput")

    def frontend_root = @contents.fetch("frontendRoot")

    def vite_dev_server_port
      return DEFAULT_VITE_DEV_SERVER_PORT if !@contents.key?("viteDevServerPort")

      value = @contents.fetch("viteDevServerPort")
      if !value.is_a?(Integer)
        raise "Invalid viteDevServerPort in #{@shared_json_path}: expected an Integer, got #{value.inspect}"
      end
      value
    end

    def manifest_path = File.join(frontend_root, @vite_manifest_relpath)

    def manifest
      @manifest ||= Manifest.new(config: self, manifest_path: manifest_path)
    end
  end

  class Manifest
    def initialize(config:, manifest_path:)
      @config = config
      @manifest_path = manifest_path
    end

    def contents
      if instance_variable_defined?(:@contents)
        return @contents
      end

      @contents =
        if File.exist?(@manifest_path)
          JSON.parse(File.read(@manifest_path))
        else
          {}
        end
    end
  end
end

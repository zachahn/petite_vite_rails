require_relative "petite_vite_rails/version"
require_relative "petite_vite_rails/view_helper"
require_relative "petite_vite_rails/railtie"

module PetiteVite
  class << self
    attr_accessor :config
  end

  class Config
    def initialize(shared_json_path:, vite_manifest_relpath:)
      @contents = JSON.parse(File.read(shared_json_path))
      @vite_manifest_relpath = vite_manifest_relpath
    end

    def build_command = @contents.fetch("buildCommand")

    def entrypoint_output = @contents.fetch("entrypointOutput")

    def frontend_root = @contents.fetch("frontendRoot")

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

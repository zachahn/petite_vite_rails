require_relative "petite_vite_rails/version"
require_relative "petite_vite_rails/view_helper"
require_relative "petite_vite_rails/railtie"

module PetiteVite
  class Config
    def initialize(path)
      @contents = JSON.parse(File.read(path))
    end

    def build_command = @contents.fetch("buildCommand")

    def entrypoint_output = @contents.fetch("entrypointOutput")

    def frontend_root = @contents.fetch("frontendRoot")
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

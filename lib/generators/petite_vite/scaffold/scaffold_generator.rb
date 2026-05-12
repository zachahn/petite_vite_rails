require "json"

module PetiteVite
  class ScaffoldGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def self.exit_on_failure?
      true
    end

    class_option :route_root, type: :boolean, default: false,
      banner: "Add `root \"petite_vite#page\"` to config/routes.rb"
    class_option :route_all, type: :boolean, default: false,
      banner: "Add `get \"*path\", to: \"petite_vite#page\"` to config/routes.rb"

    def verify_input
      mount_id!
    end

    def create_controller
      template("controller.rb", "app/controllers/petite_vite_controller.rb")
    end

    def create_view
      template("page.html.erb", "app/views/petite_vite/page.html.erb")
    end

    def insert_root_route
      return unless options.fetch("route_root")

      routes_path = File.join(destination_root, "config/routes.rb")
      if File.read(routes_path) =~ /^\s*root\s/
        say_status("skip", "root route already defined in config/routes.rb", :yellow)
        return
      end

      insert_into_file("config/routes.rb", after: %r{Rails\.application\.routes\.draw do\n}, verbose: false) do
        "  root \"petite_vite#page\"\n"
      end
    end

    def insert_catchall_route
      return unless options.fetch("route_all")

      insert_into_file("config/routes.rb", before: %r{^end\s*\z}, verbose: false) do
        "  get \"*path\", to: \"petite_vite#page\"\n"
      end
    end

    private

    def frontend_root!
      @frontend_root ||= begin
        shared_path = File.join(destination_root, "config/petite_vite.json")
        unless File.exist?(shared_path)
          raise "Expected #{shared_path} to exist. Run `rails g petite_vite:install` first."
        end
        JSON.parse(File.read(shared_path)).fetch("frontendRoot")
      end
    end

    def index_html_path!
      @index_html_path ||= begin
        path = File.join(destination_root, frontend_root!, "index.html")
        unless File.exist?(path)
          raise "Expected #{path} to exist."
        end
        path
      end
    end

    def mount_id!
      @mount_id ||= begin
        contents = File.read(index_html_path!)
        match = contents.match(/<div\b[^>]*\bid=["']([^"']+)["']/i)
        unless match
          raise "Could not determine mount-point id from #{index_html_path!}. Expected a <div id=\"...\"> element."
        end
        match[1]
      end
    end
  end
end

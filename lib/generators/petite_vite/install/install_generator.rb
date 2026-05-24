module PetiteVite
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def self.exit_on_failure?
      true
    end

    class_option :vite_dev_server_port, type: :numeric, default: 5173,
      banner: "Port for the Vite dev server"
    class_option :frontend_root, type: :string, default: "frontend",
      banner: "Path to frontend (Vite) project"
    class_option :rails_development_url, type: :string, default: "http://localhost:3000",
      banner: "Specifies the Rails development server URL"
    class_option :skip_frontend_check, type: :boolean, default: false,
      banner: "Skip the check that frontend (Vite) project exists"

    def verify_input
      vite_dev_server_port!
      frontend_root!
      rails_development_url!
      skip_frontend_check!
    end

    def verify_frontend_exists
      return if skip_frontend_check!

      path = File.join(destination_root, frontend_root!)
      unless File.exist?(path)
        raise "Expected #{path} to exist. Pass --skip-frontend-check to bypass."
      end

      path = File.join(destination_root, frontend_root!, "package.json")
      unless File.exist?(path)
        raise "Expected #{path} to exist. Pass --skip-frontend-check to bypass."
      end
    end

    def create_initializer
      template("initializer.rb", "config/initializers/petite_vite.rb")
      template("petite_vite.json", "config/petite_vite.json")
    end

    def create_package_json
      template("package.json", "package.json")
    end

    def create_dev_scripts
      return if File.exist?(File.join(destination_root, "Procfile.dev"))

      template("Procfile.dev", "Procfile.dev")
      template("bin/dev", "bin/dev")
      chmod("bin/dev", 0o755)
    end

    def insert_to_procfile_dev
      append_to_file("Procfile.dev", "vite: cd #{frontend_root!} && yarn dev\n")
    end

    def insert_to_frontend_source_main
      prepend_to_file(File.join(destination_root, frontend_root!, frontend_source_main!), "import 'vite/modulepreload-polyfill'\n")
    end

    def insert_to_vite_config
      vite_config_path = File.join(destination_root, frontend_root!, frontend_vite_config!)

      depth = frontend_root!.count("/") + 1
      relative_prefix = "../" * depth
      insert_into_file(vite_config_path, before: %r{^\s*export default defineConfig\b}, verbose: false) do
        "import shared from '#{relative_prefix}config/petite_vite.json'\n"
      end

      injected = <<~SCRIPT.indent(2)
        clearScreen: false,
        server: {
          cors: {
            origin: shared.viteCorsOrigin,
          },
          origin: shared.viteCorsOrigin,
          port: shared.viteDevServerPort,
          strictPort: true,
        },
        build: {
          manifest: true,
          rollupOptions: {
            input: shared.frontendInput,
          },
        },
      SCRIPT

      gsub_file(vite_config_path, %r{(export default defineConfig\s*\(\s*\{\s*\n)}, "\\1#{injected}", verbose: false)
    end

    def insert_to_layout
      Dir.glob(File.join(destination_root, "app", "views", "layouts", "**.html.erb")).each do |abspath|
        basename = File.basename(abspath)
        next if basename == "mailer.html.erb"
        relpath = Pathname.new(abspath).relative_path_from(destination_root).to_s
        insert_into_file(relpath, before: %r{^\s*</head>}, verbose: false) do
          "<%= vite_tags %>\n"
        end
      end
    end

    private

    def vite_dev_server_port!
      @options_vite_dev_server_port ||=
        options
          .fetch("vite_dev_server_port")
          .yield_self do |value|
            port = Integer(value)
            raise "Invalid option: vite_dev_server_port must be between 1 and 65535" if port < 1 || port > 65535
            port
          end
    end

    def frontend_root!
      @options_frontend_root ||=
        options
          .fetch("frontend_root")
          .sub(%r{/+\z}, "")
          .tap do |result|
            raise "Invalid option: frontend_root must not be the Rails root directory" if result == "." || result.empty?
            raise "Invalid option: frontend_root must not start with /" if result.start_with?("/")
            raise "Invalid option: frontend_root must only have [a-z0-9_/-]" if !%r{\A[a-z0-9_/-]+\z}i.match?(result)
          end
    end

    def rails_development_url!
      @options_rails_development_url ||=
        options
          .fetch("rails_development_url")
          .yield_self do
            u = URI(it)
            u.path = ""
            u.fragment = nil
            u.query = nil
            u.to_s
          end
    end

    def skip_frontend_check!
      if @options_skip_frontend_check.nil?
        @options_skip_frontend_check = options.fetch("skip_frontend_check")
      end

      @options_skip_frontend_check
    end

    def frontend_source_main!
      @frontend_source_main ||= begin
        basenames = %w[main index]
        extnames = %w[ts tsx js jsx]
        found = Dir.glob("{#{basenames.join(",")}}.{#{extnames.join(",")}}", base: File.join(destination_root, frontend_root!, "src")).first
        unless found
          candidates = basenames.product(extnames).map { |b, e| "src/#{b}.#{e}" }
          raise "Expected one of #{candidates.join(", ")} to exist in #{frontend_root!}."
        end
        "/src/#{found}"
      end
    end

    # Vite's dev server strips a .ts extension when serving (so /src/main.js
    # resolves to main.ts), but does NOT do this for .tsx/.jsx — those must be
    # requested with their original extension.
    def frontend_output!
      @frontend_output ||= frontend_source_main!.sub(/\.ts\z/, ".js")
    end

    def frontend_vite_config!
      @frontend_vite_config ||= begin
        ts = File.join(destination_root, frontend_root!, "vite.config.ts")
        js = File.join(destination_root, frontend_root!, "vite.config.js")
        if File.exist?(ts)
          "vite.config.ts"
        elsif File.exist?(js)
          "vite.config.js"
        else
          raise "Expected #{ts} or #{js} to exist."
        end
      end
    end
  end
end

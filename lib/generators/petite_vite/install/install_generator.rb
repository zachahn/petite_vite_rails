module PetiteVite
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    class_option :frontend_root, type: :string, default: "frontend",
      banner: "Path to frontend (Vite) repo"
    class_option :rails_server_port, type: :string, default: "3000",
      banner: "Specifies the route namespace for admin controllers"

    def create_initializer
      template("initializer.rb", "config/initializers/petite_vite.rb")
      template("petite_vite.json", "config/petite_vite.json")
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
  end
end

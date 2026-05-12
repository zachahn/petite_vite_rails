module PetiteViteRails
  class Railtie < ::Rails::Railtie
    initializer "petite_vite_rails.helpers" do
      ActiveSupport.on_load(:action_view) do
        include PetiteVite::ViewHelper
      end
    end

    rake_tasks do
      load File.expand_path("../tasks/petite_vite.rake", __dir__)
    end
  end
end

module PetiteViteRails
  class Railtie < ::Rails::Railtie
    initializer "petite_vite_rails.helpers" do
      ActiveSupport.on_load(:action_view) do
        include PetiteVite::ViewHelper
      end
    end
  end
end

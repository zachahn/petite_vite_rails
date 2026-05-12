module PetiteViteRails
  module E2ECells
    ALL = [
      {
        name: "rails-8-0-sprockets-vue-ts",
        rails: "8-0",
        pipeline: "sprockets",
        frontend_template: "vue-ts",
        rails_new_args: []
      },
      {
        name: "rails-8-0-propshaft-react",
        rails: "8-0",
        pipeline: "propshaft",
        frontend_template: "react",
        rails_new_args: []
      },
      {
        name: "rails-8-1-propshaft-vue-web",
        rails: "8-1",
        pipeline: "propshaft",
        frontend_template: "vue",
        frontend_root: "web",
        rails_new_args: []
      },
      {
        name: "rails-8-1-sprockets-react-ts",
        rails: "8-1",
        pipeline: "sprockets",
        frontend_template: "react-ts",
        rails_new_args: []
      }
    ].freeze
  end
end

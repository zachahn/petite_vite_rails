module PetiteViteRails
  module E2ECells
    ALL = [
      {
        name: "rails-8-0-sprockets-vue-ts",
        rails: "8-0",
        pipeline: "sprockets",
        create_command: ["yarn", "create", "vite", "--template", "vue-ts"],
        rails_new_args: []
      },
      {
        name: "rails-8-0-propshaft-react-nested",
        rails: "8-0",
        pipeline: "propshaft",
        create_command: ["yarn", "create", "vite", "--template", "react"],
        frontend_root: "app/frontend",
        rails_new_args: []
      },
      {
        name: "rails-8-1-propshaft-vue-web",
        rails: "8-1",
        pipeline: "propshaft",
        create_command: ["yarn", "create", "vite", "--template", "vue"],
        frontend_root: "web",
        rails_new_args: []
      },
      {
        name: "rails-8-1-sprockets-react-ts",
        rails: "8-1",
        pipeline: "sprockets",
        create_command: ["yarn", "create", "vite", "--template", "react-ts"],
        rails_new_args: []
      },
      {
        name: "rails-8-0-propshaft-svelte",
        rails: "8-0",
        pipeline: "propshaft",
        create_command: ["yarn", "create", "vite", "--template", "svelte"],
        rails_new_args: []
      },
      {
        name: "rails-8-1-sprockets-solid",
        rails: "8-1",
        pipeline: "sprockets",
        create_command: ["yarn", "create", "vite", "--template", "solid"],
        rails_new_args: []
      },
      {
        name: "rails-8-1-propshaft-create-vue",
        rails: "8-1",
        pipeline: "propshaft",
        create_command: ["yarn", "create", "vue", "--default"],
        rails_new_args: []
      }
    ].freeze
  end
end

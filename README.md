# A Petite Vite integration Rails

PetiteVite is small Rails plugin that wires a standard Vite frontend into a Rails app. It provides a convention of keeping your Rails and Vite configuration in sync, as well as a few integration helpers.

Whether PetiteVite fits your use-case depends on what you need.

**Pros**

- **Just a configuration bridge.** There is no companion npm package to install, version, or keep in sync with the gem. Fewer moving parts means less to break and less to maintain.
- **You own the Vite project.** You can create your Vite app using standard Vite templates. You own its configuration, and you don't have to learn a plugin's wrapper around anything.
- **Standard tooling.** Rails developers will be familiar with the backend codebase, and Vite developers will be familiar with the frontend codebase. There is nothing exotic to deploy or learn.
- **Small surface area.** A view helper, an install generator, a scaffold generator, and a couple of rake task hooks.

**Cons**

- **Fewer features.** PetiteVite does not offer a deep integration with Rails. You stay closer to raw Vite, but you're able to configure it however you'd like.
- **Some manual setup.** You will need to create the Vite project yourself. It will help if you're familiar with Vue.
- **No integration between the Rails router and the frontend router.**

## Installation

```sh
bundle add petite_vite_rails
```

## Usage

### 1. Setup Vite Project

Create a Vite project within your Rails app (e.g. with `yarn create vite <path/to/frontend>`). I recommend putting it under the folder `frontend` or `app/frontend`. Note that `vanilla` is not supported (you may be able to use `jsbundling-rails`?).

```
my-rails-site
├── app
│   ├── assets
│   ├── controllers
│   ├── frontend ← *also recommended*
│   ├── models
│   └── views
├── frontend ← *most recommended*
├── Gemfile
└── ...
```

### 2. Install PetiteVite

Then, run the install generator. This sets up required configuration in addition to editing a few key files.

```sh
rails generate petite_vite:install --frontend-root <path/to/frontend> # defaults to "frontend"
```

Run `rails generate petite_vite:install --help` for all available options.

### 3. Setup a controller

Your frontend framework will probably need a mount point — the HTML element where the frontend app would be rendered in. Run the scaffold generator to create the controller and view, and optionally to generate routes.

```sh
rails generate petite_vite:scaffold --route-root --route-all
```

Run `rails generate petite_vite:scaffold --help` for all available options.

### 4. Start your app with `bin/dev`

Run `bin/dev` (see `Procfile.dev`) to run both the Vite development server and the Rails server. The Vite server allows for auto-reloads.

### 5. Production deploys

PetiteVite integrates with `rails assets:precompile`. PetiteVite does NOT support running the Vite server in production.

## Tips

- I like to set up a frontend router. I then create server routes for each frontend-based route. These routes just render the mountpoint, and the frontend app takes care of the rest.

## Similar projects

- [Vite Ruby](https://github.com/elmassimo/vite_ruby)
- [RailsVite](https://github.com/skryukov/rails_vite)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

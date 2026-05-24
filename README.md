# A Petite Vite integration Rails

A small Rails plugin that wires a Vite frontend into a Rails app. It provides a `vite_tags` view helper, an install generator, and rake task hooks — nothing more.

The Vite project lives in a subdirectory (e.g. `frontend/`) and is wired up as a [yarn workspace](https://yarnpkg.com/features/workspaces).

In development, `vite_tags` emits script tags pointing at the Vite dev server. In production, it reads Vite's `manifest.json` and emits hashed asset tags with `modulepreload` links, following Vite's [backend integration](https://vite.dev/guide/backend-integration.html) recipe.

## Installation

```sh
bundle add petite_vite_rails
```

## Usage

### 1. Setup Vite Project

Create a Vite project within your Rails app (e.g. with `yarn create vue <path/to/frontend>`). I recommend putting it under the folder `frontend` or `app/frontend`.

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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Tips

A collection of patterns I've reached for while building on PetiteVite. They aren't part of the gem — they're conventions that smooth over the rough edges of running a Vite SPA behind Rails.

## Handle hard reloads in a Rails-backed Vite SPA

### How to do it

For every path your frontend router handles, declare a Rails route that renders the mountpoint. Keep these routes in their own file so they read cleanly against the frontend's route table.

In `config/routes.rb`, draw the file:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ...api routes, health checks, sessions...

  draw(:vite)
end
```

In `config/routes/vite.rb`, list each frontend path, all pointing at the controller that renders the mountpoint:

```ruby
# config/routes/vite.rb
get "dashboard", to: "vite#show"
resources :projects, controller: "vite", only: %i[index show new edit]
get "settings", to: "vite#show", as: :settings
get "settings/:section", to: "vite#show", as: :settings_section
resources :reports, controller: "vite", only: %i[index show]
```

Declare the same paths in the frontend router. Vue Router is shown here; React Router or any other client-side router follows the same shape:

```ts
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/dashboard', component: Dashboard },
    { path: '/projects', component: ProjectIndex },
    { path: '/projects/new', component: ProjectNew },
    { path: '/projects/:id', component: ProjectShow },
    { path: '/projects/:id/edit', component: ProjectEdit },
    { path: '/settings', component: Settings },
    { path: '/settings/:section', component: SettingsSection },
    { path: '/reports', component: ReportIndex },
    { path: '/reports/:id', component: ReportShow },
  ],
})
```

When you add a screen, add it in both files. That's the whole discipline.

### Why it works

PetiteVite hands routing to your frontend framework. A frontend route like `/projects/42/settings` lives entirely in the browser, and the Rails router has never heard of it. The frontend router only takes over *after* the first page loads. Before that, every request is a normal HTTP request that Rails has to answer.

So the first time a user reloads that page, deep-links into it, or shares the URL, the request lands on Rails. Without a matching route, Rails answers with a 404.

The mirror closes that gap. Each path appears on both sides: Rails answers the initial request and any reload by serving the page shell, and the frontend app then boots, reads the URL, and renders the matching view. From there the frontend router answers every navigation.

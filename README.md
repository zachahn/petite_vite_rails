# PetiteViteRails
Short description and motivation.

## Usage
How to use my plugin.

1. Run `yarn create vue $NEW_FRONTEND_DIRECTORY`.
    - I suggest using `frontend` as the directory. PetiteViteRails does not support subdirectories (`app/frontend` does not work)
2. Run `rails g petite_vite:install --frontend-root $NEW_FRONTEND_DIRECTORY`

## Installation
Run `bundle add petite_vite_rails` inside your Rails app directory.

## Contributing
Contribution directions go here.

To regenerate the Rails test dummy:

```sh
rails plugin new . --skip --no-rc --database=sqlite3 --no-skip-javascript --skip-rubocop --dummy-path=test/dummy
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

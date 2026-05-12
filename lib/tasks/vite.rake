namespace :vite do
  task build: :environment do
    frontend_root = Rails.root / VITE_CONFIG.frontend_root

    Dir.chdir(frontend_root) do
      sh VITE_CONFIG.build_command
    end
  end

  task place: :environment do
    frontend_root = Rails.root / VITE_CONFIG.frontend_root
    rails_asset_root = Rails.root / "public" / "assets"
    rails_asset_root.mkdir if !rails_asset_root.directory?

    frontend_root.join("dist", "assets").each_child do |asset|
      cp asset, rails_asset_root
    end
  end
end

return if ENV["SKIP_JS_BUILD"]

if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance(["vite:build", "vite:place"])
end

["test:prepare", "spec:prepare"].each do |test_prepare|
  if Rake::Task.task_defined?(test_prepare)
    Rake::Task[test_prepare].enhance(["vite:build", "vite:place"])
    break
  end
end

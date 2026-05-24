require_relative "lib/petite_vite_rails/version"

Gem::Specification.new do |spec|
  spec.name = "petite_vite_rails"
  spec.version = PetiteViteRails::VERSION
  spec.authors = ["Zach Ahn"]
  spec.email = ["engineering@zachahn.com"]
  spec.homepage = "https://github.com/zachahn/petite_vite_rails"
  spec.summary = "A petite Vite integration for Rails"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md", "*.gemspec"]
      .select { |path| File.file?(path) }
      .sort
  end

  spec.add_dependency "rails", ">= 8.0.0"
end

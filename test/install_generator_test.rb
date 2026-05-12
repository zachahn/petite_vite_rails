require "test_helper"
require "rails/generators/test_case"
require "generators/petite_vite/install/install_generator"

class PetiteVite::InstallGeneratorTest < Rails::Generators::TestCase
  tests PetiteVite::InstallGenerator
  destination File.expand_path("../tmp/install_generator", __dir__)
  setup :prepare_destination

  def test_inserts_vite_tags_into_application_layout
    layout_path = File.join(destination_root, "app/views/layouts/application.html.erb")
    FileUtils.mkdir_p(File.dirname(layout_path))
    File.write(layout_path, <<~ERB)
      <!DOCTYPE html>
      <html>
        <head>
          <title>Dummy</title>
        </head>
        <body></body>
      </html>
    ERB

    run_generator

    assert_includes File.read(layout_path), "<%= vite_tags %>"
  end

  def test_skips_the_mailer_layout
    mailer_layout_path = File.join(destination_root, "app/views/layouts/mailer.html.erb")
    FileUtils.mkdir_p(File.dirname(mailer_layout_path))
    original = "<html><head></head><body></body></html>"
    File.write(mailer_layout_path, original)

    run_generator

    assert_equal original, File.read(mailer_layout_path)
  end
end

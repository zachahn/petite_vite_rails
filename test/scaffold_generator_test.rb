require "test_helper"
require "json"
require "rails/generators/test_case"
require "generators/petite_vite/scaffold/scaffold_generator"

class PetiteVite::ScaffoldGeneratorTest < Rails::Generators::TestCase
  tests PetiteVite::ScaffoldGenerator
  destination File.expand_path("../tmp/scaffold_generator", __dir__)
  setup :prepare_destination

  def test_creates_controller_and_view_with_detected_mount_id
    seed(index_html: %(<html><body><div id="app"></div></body></html>))

    run_generator

    assert_file "app/controllers/petite_vite_controller.rb"
    assert_file "app/views/petite_vite/page.html.erb" do |contents|
      assert_includes contents, %(<div id="app"></div>)
    end
  end

  def test_detects_react_style_mount_id
    seed(index_html: %(<html><body><div id="root"></div></body></html>))

    run_generator

    assert_file "app/views/petite_vite/page.html.erb" do |contents|
      assert_includes contents, %(<div id="root"></div>)
    end
  end

  def test_raises_when_petite_vite_json_missing
    assert_raises(RuntimeError) { run_generator }
  end

  def test_raises_when_index_html_missing
    seed(index_html: nil)

    assert_raises(RuntimeError) { run_generator }
  end

  def test_raises_when_no_div_with_id
    seed(index_html: "<html><body><div></div></body></html>")

    assert_raises(RuntimeError) { run_generator }
  end

  def test_route_root_adds_root_route
    seed(index_html: %(<div id="app"></div>), routes: "Rails.application.routes.draw do\nend\n")

    run_generator(["--route-root"])

    assert_file "config/routes.rb" do |contents|
      assert_includes contents, %(root "petite_vite#page")
    end
  end

  def test_route_root_skips_when_already_defined
    seed(
      index_html: %(<div id="app"></div>),
      routes: %(Rails.application.routes.draw do\n  root "home#index"\nend\n),
    )

    run_generator(["--route-root"])

    assert_file "config/routes.rb" do |contents|
      refute_includes contents, "petite_vite#page"
      assert_includes contents, %(root "home#index")
    end
  end

  def test_route_all_adds_catchall
    seed(index_html: %(<div id="app"></div>), routes: "Rails.application.routes.draw do\nend\n")

    run_generator(["--route-all"])

    assert_file "config/routes.rb" do |contents|
      assert_includes contents, %(get "*path", to: "petite_vite#page")
    end
  end

  def test_route_root_and_route_all_coexist
    seed(index_html: %(<div id="app"></div>), routes: "Rails.application.routes.draw do\nend\n")

    run_generator(["--route-root", "--route-all"])

    assert_file "config/routes.rb" do |contents|
      assert_includes contents, %(root "petite_vite#page")
      assert_includes contents, %(get "*path", to: "petite_vite#page")
    end
  end

  def test_no_route_options_leaves_routes_untouched
    original = "Rails.application.routes.draw do\nend\n"
    seed(index_html: %(<div id="app"></div>), routes: original)

    run_generator

    assert_file "config/routes.rb" do |contents|
      assert_equal original, contents
    end
  end

  private

  def seed(index_html:, frontend_root: "frontend", routes: nil)
    FileUtils.mkdir_p(File.join(destination_root, "config"))
    FileUtils.mkdir_p(File.join(destination_root, frontend_root))
    File.write(
      File.join(destination_root, "config/petite_vite.json"),
      JSON.dump("frontendRoot" => frontend_root),
    )
    if index_html
      File.write(File.join(destination_root, frontend_root, "index.html"), index_html)
    end
    if routes
      File.write(File.join(destination_root, "config/routes.rb"), routes)
    end
  end
end

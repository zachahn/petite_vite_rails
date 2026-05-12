require "test_helper"
require "rake"

class ViteRakeTest < ActiveSupport::TestCase
  RAKE_PATH = File.expand_path("../lib/tasks/vite.rake", __dir__)

  setup do
    @rake = Rake::Application.new
    @previous_rake = Rake.application
    Rake.application = @rake
    Rake::Task.clear
  end

  teardown do
    Rake.application = @previous_rake
  end

  def test_defines_vite_build_and_vite_place_tasks
    load RAKE_PATH

    assert Rake::Task.task_defined?("vite:build")
    assert Rake::Task.task_defined?("vite:place")
  end

  def test_enhances_assets_precompile_when_defined
    Rake::Task.define_task("assets:precompile")

    load RAKE_PATH

    assert_equal ["vite:build", "vite:place"], Rake::Task["assets:precompile"].prerequisites
  end

  def test_enhances_test_prepare_when_defined
    Rake::Task.define_task("test:prepare")

    load RAKE_PATH

    assert_equal ["vite:build", "vite:place"], Rake::Task["test:prepare"].prerequisites
  end

  def test_skip_js_build_short_circuits_enhancement
    Rake::Task.define_task("assets:precompile")

    ENV["SKIP_JS_BUILD"] = "1"
    begin
      load RAKE_PATH
    ensure
      ENV.delete("SKIP_JS_BUILD")
    end

    assert_empty Rake::Task["assets:precompile"].prerequisites
  end
end

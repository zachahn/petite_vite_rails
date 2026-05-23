require "minitest/autorun"
require_relative "harness"
require_relative "cells"

class PetiteViteE2ETest < Minitest::Test
  PetiteViteRails::E2ECells::ALL.each do |cell|
    define_method("test_#{cell[:name].tr('-', '_')}") do
      run_cell(cell)
    end
  end

  private

  def run_cell(cell)
    workdir = PetiteViteRails::E2EHarness.prepare_workdir(cell)
    vite_port = PetiteViteRails::E2EHarness.free_port
    rails_port = PetiteViteRails::E2EHarness.free_port
    PetiteViteRails::E2EHarness.run_install_generator(cell, workdir, dev_server_port: vite_port, rails_port: rails_port)
    PetiteViteRails::E2EHarness.assert_install_artifacts(self, cell, workdir)
    PetiteViteRails::E2EHarness.run_scaffold_generator(cell, workdir)
    assert_scaffold_artifacts(workdir)

    smoke_dev_mode(cell, workdir, vite_port: vite_port, rails_port: rails_port)
    smoke_prod_mode(cell, workdir)
  ensure
    if workdir && ENV["KEEP_TMP"] == "0"
      FileUtils.rm_rf(workdir)
    end
  end

  def assert_scaffold_artifacts(workdir)
    assert_path_exists File.join(workdir, "app/controllers/petite_vite_controller.rb")
    view_path = File.join(workdir, "app/views/petite_vite/page.html.erb")
    assert_path_exists view_path
    assert_match(/<div id="[^"]+"><\/div>/, File.read(view_path))
    assert_includes File.read(File.join(workdir, "config/routes.rb")), %(root "petite_vite#page")
  end

  def smoke_dev_mode(cell, workdir, vite_port:, rails_port:)
    pid = PetiteViteRails::E2EHarness.spawn_pgroup({ "BUNDLE_GEMFILE" => nil, "PORT" => rails_port.to_s }, ["bin/dev"], chdir: workdir)
    register_cleanup(pid)
    begin
      PetiteViteRails::E2EHarness.poll_ready("http://localhost:#{rails_port}/")
      PetiteViteRails::E2EHarness.poll_ready("http://localhost:#{vite_port}/@vite/client")

      res = PetiteViteRails::E2EHarness.http_get("http://localhost:#{rails_port}/")
      assert_match %r{http://localhost:#{vite_port}/src/main\.(tsx|jsx|ts|js)}, res.body

      asset_url = res.body[%r{http://localhost:#{vite_port}/src/main\.(?:tsx|jsx|ts|js)}]
      asset_res = PetiteViteRails::E2EHarness.http_get(asset_url)
      assert_equal "200", asset_res.code
      assert_match %r{(text|application)/javascript}, asset_res["content-type"].to_s
      assert asset_res.body.bytesize > 0, "expected dev entry JS body to be non-empty"
    ensure
      PetiteViteRails::E2EHarness.kill_pgroup(pid)
    end
  end

  def smoke_prod_mode(cell, workdir)
    env = { "RAILS_ENV" => "production", "SECRET_KEY_BASE" => "test", "BUNDLE_GEMFILE" => nil }
    PetiteViteRails::E2EHarness.run!(env, ["bundle", "exec", "rails", "assets:precompile"], chdir: workdir, label: "assets:precompile")

    assert Dir[File.join(workdir, "public/assets/*.js")].any?, "expected public/assets/*.js after precompile"
    assert_path_exists File.join(workdir, PetiteViteRails::E2EHarness.frontend_root(cell), "dist/.vite/manifest.json")

    rails_port = PetiteViteRails::E2EHarness.free_port
    pid = PetiteViteRails::E2EHarness.spawn_pgroup(env.merge("PORT" => rails_port.to_s), ["bundle", "exec", "rails", "s"], chdir: workdir)
    register_cleanup(pid)
    begin
      PetiteViteRails::E2EHarness.poll_ready("http://localhost:#{rails_port}/")
      res = PetiteViteRails::E2EHarness.http_get("http://localhost:#{rails_port}/")
      m = res.body.match(%r{/assets/[^"']+\.js})
      assert m, "expected digested asset path in HTML"
      asset_res = PetiteViteRails::E2EHarness.http_get("http://localhost:#{rails_port}#{m[0]}")
      assert_equal "200", asset_res.code
      assert_match %r{(text|application)/javascript}, asset_res["content-type"].to_s
      assert asset_res.body.bytesize > 0, "expected prod entry JS body to be non-empty"

      css_match = res.body.match(%r{/assets/[^"']+\.css})
      assert css_match, "expected digested CSS path in HTML"
      css_res = PetiteViteRails::E2EHarness.http_get("http://localhost:#{rails_port}#{css_match[0]}")
      assert_equal "200", css_res.code
      assert_match %r{text/css}, css_res["content-type"].to_s
      assert css_res.body.bytesize > 0, "expected prod CSS body to be non-empty"
    ensure
      PetiteViteRails::E2EHarness.kill_pgroup(pid)
    end
  end

  def register_cleanup(pid)
    @cleanup_pids ||= []
    @cleanup_pids << pid
    at_exit { PetiteViteRails::E2EHarness.kill_pgroup(pid) }
  end

  def assert_path_exists(path, msg = nil)
    assert File.exist?(path), msg || "expected #{path} to exist"
  end
end

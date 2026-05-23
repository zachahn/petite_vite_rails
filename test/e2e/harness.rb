require "bundler"
require "fileutils"
require "json"
require "net/http"
require "open3"
require "shellwords"
require "socket"
require "uri"

module PetiteViteRails
  module E2EHarness
    ROOT = File.expand_path("../..", __dir__)
    WORK_ROOT = File.join(ROOT, "tmp/e2e")
    READY_TIMEOUT_S = 60

    module_function

    def prepare_workdir(cell)
      FileUtils.mkdir_p(WORK_ROOT)
      workdir = File.join(WORK_ROOT, cell.fetch(:name))
      FileUtils.rm_rf(workdir)
      rails_new(cell, workdir)
      apply_gemfile_overlay(workdir)
      run!({ "BUNDLE_GEMFILE" => nil }, ["bundle", "install"], chdir: workdir, label: "bundle install (overlay) (#{File.basename(workdir)})")
      generate_frontend(cell, workdir)
      workdir
    end

    def frontend_root(cell)
      cell[:frontend_root] || "frontend"
    end

    def rails_new(cell, dest)
      gemfile = File.join(ROOT, "gemfiles/rails-#{cell[:rails]}")
      args = ["bundle", "exec", "rails", "new", dest, "--skip-bundle", "--skip-git", "--skip-test", "--skip-system-test", "--skip-javascript", "--asset-pipeline", cell[:pipeline]] + Array(cell[:rails_new_args])
      env = { "BUNDLE_GEMFILE" => gemfile }
      run!(env, args, chdir: ROOT, label: "rails new (#{cell[:name]})")
    end

    def apply_gemfile_overlay(dest)
      gemfile_path = File.join(dest, "Gemfile")
      gemfile_body = File.read(gemfile_path)
      marker = "# petite_vite_rails e2e overlay"
      return if gemfile_body.include?(marker)
      gemfile_body << "\n#{marker}\n"
      gemfile_body << %(gem "petite_vite_rails", path: #{ROOT.inspect}\n)
      gemfile_body << %(gem "foreman", group: :development\n)
      File.write(gemfile_path, gemfile_body)
    end

    def generate_frontend(cell, workdir)
      dir = frontend_root(cell)
      run!({ "BUNDLE_GEMFILE" => nil }, ["yarn", "create", "vite", dir, "--template", cell[:frontend_template]], chdir: workdir, label: "yarn create vite (#{cell[:name]})")
      run!({ "BUNDLE_GEMFILE" => nil }, ["yarn", "install"], chdir: File.join(workdir, dir), label: "yarn install (#{cell[:name]})")
    end

    def run_install_generator(cell, workdir, dev_server_port:)
      bin_dev = File.join(workdir, "bin/dev")
      File.unlink(bin_dev) if File.exist?(bin_dev)
      args = ["bundle", "exec", "rails", "g", "petite_vite:install", "--dev-server-port", dev_server_port.to_s]
      args += ["--frontend-root", frontend_root(cell)] if cell[:frontend_root]
      run!({ "BUNDLE_GEMFILE" => nil }, args, chdir: workdir, label: "petite_vite:install")
    end

    def run_scaffold_generator(_cell, workdir)
      args = ["bundle", "exec", "rails", "g", "petite_vite:scaffold", "--route-root"]
      run!({ "BUNDLE_GEMFILE" => nil }, args, chdir: workdir, label: "petite_vite:scaffold")
    end

    def assert_exists(test, path)
      test.assert File.exist?(path), "expected #{path} to exist"
    end

    def assert_install_artifacts(test, cell, workdir)
      dir = frontend_root(cell)
      assert_exists(test, File.join(workdir, "config/initializers/petite_vite.rb"))

      shared_json_path = File.join(workdir, "config/petite_vite.json")
      assert_exists(test, shared_json_path)
      shared = JSON.parse(File.read(shared_json_path))
      %w[buildCommand devServerPort entrypointInput entrypointOutput frontendRoot localServerCorsOrigin].each do |key|
        test.assert shared.key?(key), "expected petite_vite.json to have key #{key.inspect}"
      end
      test.assert_equal dir, shared["frontendRoot"]

      pkg_path = File.join(workdir, "package.json")
      assert_exists(test, pkg_path)
      pkg = JSON.parse(File.read(pkg_path))
      test.assert_includes Array(pkg["workspaces"]), dir

      procfile = File.join(workdir, "Procfile.dev")
      assert_exists(test, procfile)
      procfile_contents = File.read(procfile)
      test.assert_match(/^web:/, procfile_contents)
      test.assert_match(/^vite:/, procfile_contents)

      bin_dev = File.join(workdir, "bin/dev")
      assert_exists(test, bin_dev)
      test.assert File.executable?(bin_dev), "expected bin/dev to be executable"

      vite_config_path = Dir[File.join(workdir, dir, "vite.config.{ts,js}")].first
      test.assert vite_config_path, "expected #{dir}/vite.config.{ts,js} to exist"
      test.assert_includes File.read(vite_config_path), "shared.localServerCorsOrigin"

      layout = File.join(workdir, "app/views/layouts/application.html.erb")
      test.assert_includes File.read(layout), "<%= vite_tags %>"
    end

    def free_port
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr[1]
      server.close
      port
    end

    def rewrite_ports(workdir, rails_port:)
      procfile_path = File.join(workdir, "Procfile.dev")
      procfile = File.read(procfile_path)
      procfile = procfile.sub(/--port \d+/, "--port #{rails_port}")
      File.write(procfile_path, procfile)

      shared_path = File.join(workdir, "config/petite_vite.json")
      shared = JSON.parse(File.read(shared_path))
      shared["localServerCorsOrigin"] = "http://localhost:#{rails_port}"
      File.write(shared_path, JSON.pretty_generate(shared))
    end

    def poll_ready(url, timeout: READY_TIMEOUT_S)
      deadline = Time.now + timeout
      last_err = nil
      while Time.now < deadline
        begin
          uri = URI(url)
          res = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 1, read_timeout: 2) do |http|
            http.get(uri.request_uri)
          end
          return res if res.code.to_i == 200
        rescue StandardError => e
          last_err = e
        end
        sleep 0.3
      end
      raise "Timed out polling #{url}: #{last_err}"
    end

    def http_get(url)
      uri = URI(url)
      Net::HTTP.start(uri.hostname, uri.port, open_timeout: 2, read_timeout: 5) do |http|
        http.get(uri.request_uri)
      end
    end

    def spawn_pgroup(env, cmd, chdir:)
      if env["BUNDLE_GEMFILE"].nil? && env.key?("BUNDLE_GEMFILE")
        Bundler.with_unbundled_env do
          Process.spawn(env.reject { |_, v| v.nil? }, *cmd, chdir: chdir, pgroup: true, out: $stdout, err: $stderr)
        end
      else
        Process.spawn(env, *cmd, chdir: chdir, pgroup: true, out: $stdout, err: $stderr)
      end
    end

    def kill_pgroup(pid)
      return unless pid
      begin
        Process.kill("-TERM", pid)
      rescue Errno::ESRCH, Errno::EPERM
      end
      deadline = Time.now + 10
      while Time.now < deadline
        begin
          Process.waitpid(pid, Process::WNOHANG) ? break : sleep(0.1)
        rescue Errno::ECHILD
          break
        end
      end
      begin
        Process.kill("-KILL", pid)
      rescue Errno::ESRCH, Errno::EPERM
      end
    end

    def run!(env, args, chdir:, label:)
      puts "    [#{label}] #{args.shelljoin}"
      success =
        if env["BUNDLE_GEMFILE"].nil? && env.key?("BUNDLE_GEMFILE")
          Bundler.with_unbundled_env { system(env.reject { |_, v| v.nil? }, *args, chdir: chdir) }
        else
          system(env, *args, chdir: chdir)
        end
      raise "Command failed (#{label}): #{args.shelljoin}" unless success
    end
  end
end

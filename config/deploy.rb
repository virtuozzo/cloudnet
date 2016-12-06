require 'dotenv'
Dotenv.load

lock '3.2.1'

set :application, 'cloudnet'
set :deploy_user, 'deploy'
set :rails_env, 'production'
set :repo_url, ENV['GIT_ORIGIN']
set :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
set :scm, :git

set :deploy_to, '/apps/cloudnet'

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Puma related config variables
set :puma_default_hooks, false
set :puma_threads, [1, 4]
set :puma_workers, 2
set :puma_preload_app, true
set :puma_init_active_record, false
set :puma_jungle_conf, '/etc/puma.conf'
set :puma_run_path, '/usr/local/bin/run-puma'
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"

set :sidekiq_timeout, 40
set :sidekiq_run_in_background, true

set :config_files, %w(.env)
set :linked_files, %w(.env)
set :linked_dirs, %w(bin log tmp/pids tmp/cache tmp/sockets tmp/puma vendor/bundle public/system)

set :keep_releases, 10

set :whenever_roles, -> { :app }

before 'deploy:check:linked_files', 'config:push' unless ENV['CI']
before 'deploy:restart', 'puma:config'

namespace :deploy do

  desc "Run post-deploy actions (restart Puma, enable monit for Puma and Sidekiq)"
  task :post_deploy do
    invoke 'deploy:restart'
    invoke 'deploy:configure_monit'
  end

  desc "Restart Puma via Puma Jungle"
  task :restart do
    invoke 'puma:phased-restart'
  end

  desc "Configure and start Monit for Puma and Sidekiq"
  task :configure_monit do
    invoke 'puma:monit:monitor'
    invoke 'sidekiq:monit:monitor'
  end

  desc 'Seed application data'
  task :seed do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:seed'
        end
      end
    end
  end

  # desc 'Delete cached minified Javascript'
  # task :remove_cached_js do
  #   on roles(:app), in: :sequence, wait: 5 do
  #     within release_path do
  #       with rails_env: fetch(:rails_env) do
  #         execute :rake, "deploy:remove_cached_js"
  #       end
  #     end
  #   end
  # end
end

after 'deploy:check', 'puma:check'
after 'deploy:finished', 'deploy:post_deploy'
# after "deploy", "deploy:remove_cached_js"

namespace :maintenance do
  desc 'Enter maintenance mode on the website'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'maintenance:start'
        end
      end
    end
  end

  desc 'End maintenance mode on the website'
  task :end do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'maintenance:end'
        end
      end
    end
  end
end

namespace :build_checker do
  desc 'Stop build checker daemon'
  task :stop do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'build_checker:stop'
        end
      end
    end
  end

  desc 'Start build checker daemon'
  task :start do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'build_checker:start'
        end
      end
    end
  end
end

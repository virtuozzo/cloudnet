class BuildCheckerController < ApplicationController
  def start
    if BuildChecker.running?
      flash[:warning] = 'Build checker already running'
    else
      unless Rails.env == 'development'
        start_remote_build_checker
      else
        ActiveRecord::Base.connection.disconnect!
        pid = fork do
          Process.daemon
          Process.setproctitle('build checker 1.0.0')
          BuildChecker::Orchestrator.run
        end
        Process.detach(pid)
        ActiveRecord::Base.establish_connection(
          Rails.application.config.database_configuration[Rails.env]
        )

        flash[:notice] = 'Build checker started'
      end
    end

    redirect_to admin_build_checkers_path
  end

  def stop
    if BuildChecker.running?
      unless Rails.env == 'development'
        stop_remote_build_checker
      else
        Process.kill('HUP', BuildChecker.pid)
        flash[:notice] = 'Build checker stopped'
      end
    else
      flash[:warning] = 'Build checker is not running'
    end
    rescue
      flash[:error] = 'wrong server'
    ensure
      redirect_to admin_build_checkers_path
  end

  private
    def start_remote_build_checker
      host = case Rails.env
      when 'staging' then ENV['STAGING_SERVER1_IP']
      when 'production' then ENV['PROD_SERVER1_IP']
      when 'development' then ''
      end

      result = system("bundle exec cap #{Rails.env} build_checker:start HOSTS=#{host}")
      if result
        flash[:notice] = 'Build checker started'
      else
        flash[:error] = 'Not able to start build checker. Please refer to logs'
      end
    end

    def stop_remote_build_checker
      # Using capistrano for daemon stop broadcast.
      # We do not know the server, where build checker is running
      result = system("bundle exec cap #{Rails.env} build_checker:stop")
      if result
        flash[:notice] = 'Build checker stopped'
      else
        flash[:error] = 'Not able to execute stop command. Please refer to logs'
      end
    end
end

class BuildCheckerController < ApplicationController
  def start
    if BuildChecker.running?
      flash[:warning] = 'Build checker already running'
    else
      Rails.env == 'development' ? start_local_build_checker : start_remote_build_checker
    end

    redirect_to admin_build_checkers_path
  end

  def stop
    if BuildChecker.running?
      Rails.env == 'development' ? stop_local_build_checker : stop_remote_build_checker
    else
      flash[:warning] = 'Build checker is not running'
    end

    redirect_to admin_build_checkers_path
  end

  private
  # FIXME: redirect_to is not performed correctly.
  # FIXME: when using capistrano, STDOUT is redirected
    def start_remote_build_checker
      ActiveRecord::Base.connection.disconnect!
      pid = fork do
        Process.daemon(false, true)
        BuildChecker::Orchestrator.run
      end
      Process.detach(pid)
      ActiveRecord::Base.establish_connection(
        Rails.application.config.database_configuration[Rails.env]
      )
      flash[:notice] = 'Build checker started'
      # result = system("bundle exec cap #{Rails.env} build_checker:start HOSTS=#{host_address}")
      #
      # if result
      #   flash[:notice] = 'Build checker started'
      # else
      #   flash[:error] = 'Not able to start build checker. Please refer to logs'
      # end
    end

    def host_address
      case Rails.env
      when 'staging' then ENV['STAGING_SERVER1_IP']
      when 'production' then ENV['PROD_SERVER1_IP']
      else ''
      end
    end

    def start_local_build_checker
      ActiveRecord::Base.connection.disconnect!
      # to quit when development server quits
      pid = fork do
        BuildChecker::Orchestrator.run
      end
      Process.detach(pid)
      ActiveRecord::Base.establish_connection(
        Rails.application.config.database_configuration[Rails.env]
      )
      flash[:notice] = 'Build checker started'
    end

    def stop_remote_build_checker
      # Using capistrano for daemon stop broadcast.
      result = system("bundle exec cap #{Rails.env} build_checker:stop")

      if result
        flash[:notice] = 'Build checker stopped'
      else
        flash[:error] = 'Not able to execute stop command. Please refer to logs'
      end
    end

    def stop_local_build_checker
      Process.kill('INT', BuildChecker.pid)
    rescue Errno::ESRCH
      BuildChecker.clear_pid!
    ensure
      flash[:notice] = 'Build checker stopped'
    end
end

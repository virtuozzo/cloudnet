class BuildCheckerController < ApplicationController
  def start
    if BuildChecker.running?
      flash[:warning] = BuildChecker.stopping? ? 'Build checker is stopping' : 'Build checker already running'
    else
      Rails.env == 'development' ? start_local_build_checker : start_remote_build_checker
    end

    redirect_to admin_build_checkers_path
  end

  def stop
    if BuildChecker.stopped?
      flash[:warning] = 'Build checker is not running'
    elsif BuildChecker.stopping?
      flash[:warning] = 'Build checker is stopping. Wait for finish all the tasks.'
    else
      Rails.env == 'development' ? stop_local_build_checker : stop_remote_build_checker
    end

    redirect_to admin_build_checkers_path
  end

  private
    def start_remote_build_checker
      result = system("bundle exec rake build_checker:start")

      if result
        flash[:notice] = 'Build checker started'
      else
        flash[:error] = 'Not able to start build checker daemon. Please refer to logs'
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
        flash[:notice] = 'Build checker stopping'
      else
        flash[:error] = 'Not able to execute stop command. Please refer to logs'
      end
    end

    def stop_local_build_checker
      Process.kill('INT', BuildChecker.pid)
    rescue Errno::ESRCH
      BuildChecker.clear_pid!
      BuildChecker.status = :stopped
    ensure
      flash[:notice] = 'Build checker stopping'
    end
end

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
      flash[:warning] = 'Build checker is stopping. Wait to finish all the tasks.'
    else
      BuildChecker.status = "stopping"
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
end

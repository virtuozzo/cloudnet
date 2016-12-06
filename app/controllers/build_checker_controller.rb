class BuildCheckerController < ApplicationController
  def start
    if BuildChecker.running?
      flash[:warning] = 'Build checker already running'
    else
      start_build_checker
      sleep 2 # Time for forked process to fail
      pid = BuildChecker.pid
      gid = -1

      if pid > 0
        gid = Process.getpgid(pid) rescue -1
      end

      case gid
      when -1 then flash[:error] ='Unable to start build checker. Please check logs.'
      else flash[:notice] = 'Build checker started'
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
    def start_build_checker
      ActiveRecord::Base.connection.disconnect!
      pid = fork do
        Process.daemon(false, true)
        Process.setproctitle('build checker 1.0.0')
        BuildChecker::Orchestrator.run
      end
      Process.detach(pid)
      ActiveRecord::Base.establish_connection(
        Rails.application.config.database_configuration[Rails.env]
      )
      pid
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

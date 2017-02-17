# Builds test VMs using all accessible templates
module BuildChecker
  PID_KEY = 'build_checker_pid'
  STATUS_KEY = 'build_checker_status' # running, stopped, stopping
  CONCURRENT_BUILDS = 'build_checker_concurrent_builds'

  class << self
    def running?
      #(status.empty? || status == "stopped") && pid == 0 ? false : true
      status == 'running' ||  status == 'stopping' ? true : false
    end

    def stopped?
      status == "stopped"
    end

    def stopping?
      status == "stopping"
    end

    def running!
      System.set(PID_KEY, Process.pid)
      System.set(STATUS_KEY, :running)
    end

    def pid
      System.get(PID_KEY).to_i
    end

    def clear_pid!
      System.clear(PID_KEY)
    end

    def status=(status)
      System.set(STATUS_KEY, status)
    end

    def status
      System.get(STATUS_KEY)
    end

    def concurrent_builds
      System.get(CONCURRENT_BUILDS).to_i
    end

    def concurrent_builds=(number)
      number = [number.to_i, 5].min
      System.set(CONCURRENT_BUILDS, number)
    end

    def number_of_processed_tasks
      BuildChecker::Data::BuildCheckerDatum.where.not(state: non_processing_states).count
    end

    def non_processing_states
      [
        BuildChecker::Data::BuildCheckerDatum.states['scheduled'],
        BuildChecker::Data::BuildCheckerDatum.states['finished']
      ]
    end
  end
end
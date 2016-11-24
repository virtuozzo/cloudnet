module BuildChecker
  module Monitor
  # The purpose is to monitor the status of built and destroyed VMs
    class BuildMonitor
      include BuildChecker::Data
      include BuildChecker::Logger
      VERIFY_EVERY = 10.seconds
      MAX_FAST_CHECKS = 5
      at_exit do
        ActiveRecord::Base.clear_active_connections!
        logger.info "Monitor stopped"
      end

      def self.run
        new.run
      end

      def initialize
        return if @user = User.find_by(email: 'build_checker_fake_email')
        fail "You must create build_checker user before. Use: rake create_build_checker_user"
      end

      def run
        logger.info "Monitor started"
        fast_check_counter = 0
        loop do
          if fast_check_counter < MAX_FAST_CHECKS && next_to_monitor_task
            run_vm_monitor
            fast_check_counter += 1
            sleep 1  # minimize concurrent calls
          else
            fast_check_counter = 0
            sleep VERIFY_EVERY
          end
        end
      end

      def run_vm_monitor
        @task.with_lock do
          @task.state = :monitoring
          @task.save!
        end
        monitor_worker_start
      end

      def monitor_worker_start
        logger.debug "Monitoring task #{@task.inspect}"
        if @task.delete_queued_at.nil?
          VmMonitorBuild.perform_async(@task.id, @user.id)
        else
          VmMonitorDestroy.perform_async(@task.id, @user.id)
        end
      end

      def next_to_monitor_task
        @task = nil
        return if BuildCheckerDatum.where(state: to_monitor_state).count == 0
        @task = BuildCheckerDatum.lock.
          where(state: to_monitor_state).order(:updated_at).first
      end

      def to_monitor_state
        BuildCheckerDatum.states["to_monitor"]
      end
    end
  end
end
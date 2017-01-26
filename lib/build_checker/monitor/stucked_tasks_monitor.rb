module BuildChecker
  module Monitor
  # The purpose is to detect stucked tasks
  # possibilities: building, monitoring, cleaning
    class StuckedTasksMonitor
      include BuildChecker::Data
      include BuildChecker::Logger
      VERIFY_EVERY = 30.seconds
      STUCK_TIME = 2.minutes

      at_exit do
        ActiveRecord::Base.clear_active_connections!
        logger.info "Stucked Tasks Monitor stopped"
      end

      def self.run
        new.run
      end

      def initialize
        return if @user = User.find_by(email: 'build_checker_fake_email')
        fail "You must create build_checker user before. Use: rake create_build_checker_user"
      end

      def run
        logger.info "Stucked Tasks Monitor started"
        loop do
          detect_stucked_tasks
          sleep VERIFY_EVERY
        end
      end

      def detect_stucked_tasks
        tasks_to_check.each do |task|
          time_passed = (Time.now - task.updated_at).to_f
          task_to_actionable_state(task) if (time_passed / STUCK_TIME) > 1
        end
      end

      def task_to_actionable_state(task)
        case task.state
        when 'building' then finish_task_error(task)
        when 'monitoring' then task.update_attribute(:state, :to_monitor)
        when 'cleaning' then task.update_attribute(:state, :to_clean)
        end
      end

      def finish_task_error(task)
        e = task.error || "{}"
        mes = {stucked_in_state: task.state}
        task.update(
          build_result: :failed,
          state: :finished,
          error: JSON.parse(e).merge(mes).to_json
        )
      end

      def tasks_to_check
        BuildCheckerDatum.where(state: possible_stuck_state)
      end

      def possible_stuck_state
        [
          BuildCheckerDatum.states["building"],
          BuildCheckerDatum.states["monitoring"],
          BuildCheckerDatum.states["cleaning"]
        ]
      end
    end
  end
end
module BuildChecker
  module Cleaner
  # The purpose is to remove built VM at OnApp
    class CleanProcessor
      include BuildChecker::Data
      include BuildChecker::Logger
      VERIFY_EVERY = 10.seconds
      at_exit do
        ActiveRecord::Base.clear_active_connections!
        logger.info "Cleaner stopped"
      end

      def self.run
        new.run
      end

      def initialize
        return if @user = User.find_by(email: 'build_checker_fake_email')
        fail "You must create build_checker user before. Use: rake create_build_checker_user"
      end

      def run
        logger.info "Cleaner started"
        loop do
          if next_to_clean_task
            run_cleaner
            sleep 1  # minimize concurrent calls
          else
            sleep VERIFY_EVERY
          end
        end
      end

      def run_cleaner
        @task.with_lock do
          @task.state = :cleaning
          @task.save!
        end
        cleaner_worker_start
      end


      def cleaner_worker_start
        logger.debug "Cleaning task #{@task.inspect}"
        VmCleanerWorker.perform_async(@task.id, @user.id)
      end

      def next_to_clean_task
        @task = nil
        return if BuildCheckerDatum.where(state: to_clean_state).count == 0
        @task = BuildCheckerDatum.lock.
          where(state: to_clean_state).order(:updated_at).first
      end

      def to_clean_state
        BuildCheckerDatum.states["to_clean"]
      end
    end
  end
end
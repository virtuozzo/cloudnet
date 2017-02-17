module BuildChecker
  module Builder
    # The purpose is to schedule build workers based on building queue
    class BuildProcessor
      include BuildChecker::Data
      include BuildChecker::Logger
      VERIFY_EVERY = 15.seconds
      at_exit do
        ActiveRecord::Base.clear_active_connections!
        logger.info "Build Processor stopped"
      end

      def self.run
        new.run
      end

      def initialize
        return if @user = User.find_by(email: 'build_checker_fake_email')
        fail "You must create build_checker user before. Use: rake create_build_checker_user"
      end

      def run
        logger.info "Build Processor started"
        loop do
          if empty_slot? && next_scheduled_task
            start_vm_build
            sleep 1  # minimize concurrent calls
          else
            sleep VERIFY_EVERY
          end
        end
      end

      def start_vm_build
        @task.with_lock do
          @task.scheduled = nil # for unique index
          @task.state = :building
          @task.save!
        end
        build_worker_start if @task.state == "building" # in case of race condition
      end

      def build_worker_start
        logger.debug "Starting build task #{@task.inspect}"
        VmBuilderWorker.perform_async(@task.id, @user.id)
      end

      def next_scheduled_task
        @task = nil
        return if BuildCheckerDatum.
          where('scheduled IS TRUE AND start_after < ?', Time.now).count == 0

        @task = BuildCheckerDatum.lock.
          where('scheduled IS TRUE AND start_after < ?', Time.now).
          order(:start_after).first
      end

      def empty_slot?
        BuildChecker.number_of_processed_tasks < BuildChecker.concurrent_builds
      end
    end
  end
end

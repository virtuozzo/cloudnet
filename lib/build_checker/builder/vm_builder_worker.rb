module BuildChecker
  module Builder
    class VmBuilderWorker
      include BuildChecker::Data
      include BuildChecker::Logger
      include Sidekiq::Worker
      sidekiq_options unique: :until_executed
      sidekiq_options :retry => false

      def perform(task_id, user_id)
        @user = User.find(user_id)
        @task = BuildCheckerDatum.find(task_id)
        start_test_build
      end

      def start_test_build
        create_remote_server
        update_test_data
        logger.debug "Remote server info: #{@remote_server.inspect}"
      rescue Faraday::Error::ClientError, StandardError => e
        log_error(e)
        update_error_task(e)
      end

      def create_remote_server
        @remote_server = CreateServer.new(wizard, @user).process
      end

      def update_test_data
        if @remote_server && @remote_server['id']
          update_to_monitor_task
        else
          raise "OnApp did not return server creation data"
        end

      end

      def update_to_monitor_task
        @task.update(
          build_start: Time.now,
          state: :to_monitor,
          onapp_identifier: @remote_server['identifier']
        )
      end

      def update_error_task(e)
        mes = {:create => e.message}
        if e.respond_to?(:response) && e.response
          mes.merge!({:create_response => JSON.parse(e.response[:body])})
        end

        @task.update(
          build_result: :failed,
          state: :finished,
          error: mes.to_json
        )
      end

      def template
        @template ||= @task.template
      end

      def wizard
        @wizard ||= ServerWizard.new(
          template: template,
          location: template.location,
          name: 'build-checker',
          hostname: 'build.checker',
          memory: template.min_memory,
          cpus: 1,
          disk_size: template.min_disk,
          validation_reason: 0
        )
      end

      def log_error(error)
        ErrorLogging.new.track_exception(
          error,
          extra: {
            user_id: @user.id,
            task_id: @task.id,
            template_id: @task.template_id,
            source: 'BuildChecker::Builder::VmBuilderWorker',
            response: error.try(:response)
          }
        )
        logger.error "ERROR: #{error.message}"
      end
    end
  end
end

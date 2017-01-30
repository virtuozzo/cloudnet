module BuildChecker
  module Cleaner
    class VmCleanerWorker
      include BuildChecker::Data
      include BuildChecker::Logger
      include Sidekiq::Worker
      sidekiq_options unique: :until_executed

      def perform(task_id, user_id)
        set_variables(task_id, user_id)
        record_failed_transactions(task_id, user_id)
        delete_vm
        update_task_to_monitor
      rescue Faraday::Error::ClientError, StandardError => e
        log_error(e)
        update_error_task(e)
      end

      def set_variables(task_id, user_id)
        @user = User.find(user_id)
        @task = BuildCheckerDatum.find(task_id)
        @failed_transactions_number = 0
      end

      def record_failed_transactions(task_id, user_id)
        proxy = BuildChecker::Monitor::VmMonitorWorker.new
        proxy.set_variables(task_id, user_id)
        @failed_transactions_number = proxy.failed_transactions.size
      end

      def delete_vm
        logger.debug "Deleting VM: #{@task.onapp_identifier}"
        squall.delete(@task.onapp_identifier)
      end

      def update_task_to_monitor
        @task.update(
          delete_queued_at: Time.now,
          state: :to_monitor,
          failed_in_build: @failed_transactions_number
        )
      end

      def update_error_task(e)
        task_error = @task.error || "{}"
        mes = {:queue_delete => e.message}
        if e.respond_to?(:response) && e.response
          mes.merge!({:queue_delete_response => JSON.parse(e.response[:body])})
        end

        @task.update(
          build_result: :failed,
          state: :finished,
          error: JSON.parse(task_error).merge(mes).to_json
        )
      end

      def squall
        @squall ||= Squall::VirtualMachine.new(
          uri: ONAPP_CP[:uri],
          user: @user.onapp_user,
          pass: @user.onapp_password
        )
      end

      def log_error(error)
        ErrorLogging.new.track_exception(
          error,
          extra: {
            user_id: @user.id,
            task_id: @task.id,
            template_id: @task.template_id,
            onapp_server_id: @task.onapp_identifier,
            source: 'BuildChecker::`Cleaner::VmCleanerWorker',
            response: error.try(:response)
          }
        )
        logger.error "ERROR: #{error.message}"
      end
    end
  end
end
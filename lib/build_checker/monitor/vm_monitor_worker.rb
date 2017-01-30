module BuildChecker
  module Monitor
    class VmMonitorWorker
      include BuildChecker::Data
      include BuildChecker::Logger
      include Sidekiq::Worker
      sidekiq_options unique: :until_executed
      sidekiq_options :retry => 2

      def perform(task_id, user_id)
        set_variables(task_id, user_id)
        verify_vm
      end

      def set_variables(task_id, user_id)
        @user = User.find(user_id)
        @task = BuildCheckerDatum.find(task_id)
      end

      def verify_vm
        get_remote_server_info
        verify_vm_status
      end

      def get_remote_server_info
        @remote_server = squall.show(@task.onapp_identifier)
      end

      def pending_transactions
        transactions.select { |t| t['transaction']['status'] == 'pending'}
      end

      def failed_transactions
        transactions.select do |t|
          t['transaction']['status'] == 'failed' ||
          t['transaction']['status'] == 'cancelled'
        end
      end

      def transactions
        @transactions ||= squall.transactions(@task.onapp_identifier, 100)
      end

      def update_task_to_monitor
        @task.update(state: :to_monitor)
      end

      def finish_task_success
        @task.update(
          build_result: :success,
          deleted_at: Time.now,
          state: :finished
        )
      end

      def finish_task_error(e, exception: nil, timeout: nil)
        error = case e
        when :build_timeout then "Time expired - VM not built in #{timeout} sec."
        when :delete_timeout then "Time expired - VM not deleted at OnApp in #{timeout} sec."
        when :failed_transaction then 'OnApp transaction failed or cancelled.'
        when :operation_error then exception.message
        end

        update_task_error(error, exception)
      end

      def update_task_error(error, exception)
        op = @task.delete_queued_at.nil? ? :build : :delete
        e = @task.error || "{}"
        mes = {op => error}
        if exception.respond_to?(:response) && exception.response
          mes.merge!(Hash[(op.to_s + '_response'), JSON.parse(exception.response[:body])])
        end

        @task.update(
          build_result: :failed,
          state: op == :build ? :to_clean : :finished,
          error: JSON.parse(e).merge(mes).to_json
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
            source: 'BuildChecker::Monitor::VmMonitorWorker',
            response: error.try(:response)
          }
        )
        logger.error "ERROR: #{error.message}"
      end
    end
  end
end
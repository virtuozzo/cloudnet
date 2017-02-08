module BuildChecker
  module Monitor
  # The purpose is to monitor the status of VMs with destroy command queued
    class VmMonitorDestroy < VmMonitorWorker
      DELETE_TIMEOUT = 30.minutes

      # TODO: monitor delete when failed transactions from build
      def perform(task_id, user_id)
        super
      rescue Faraday::Error::ClientError, StandardError => e
        if e.is_a?(Faraday::ResourceNotFound)
          # VM properly removed at OnApp
          finish_task_success
        else
          log_error(e)
          finish_task_error(:operation_error, exception: e)
        end
      end

      def verify_vm_status
        case
        when failed_during_destroy? then finish_task_error(:failed_transaction)
        when delete_timeout_expired? then finish_task_error(:delete_timeout, timeout: DELETE_TIMEOUT)
        else update_task_to_monitor
        end
      end

      def failed_during_destroy?
        failed_transactions.size > @task.failed_in_build
      end

      def delete_timeout_expired?
        ((Time.now - @task.delete_queued_at).to_f / DELETE_TIMEOUT) > 1
      end

      def finish_task_success
        build_result = @task.build_result == "failed" ? :failed : :success
        @task.update(
          build_result: build_result,
          deleted_at: Time.now,
          state: :finished
        )
      end
    end
  end
end
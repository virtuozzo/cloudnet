module BuildChecker
  module Monitor
  # The purpose is to monitor the status of built VMs
    class VmMonitorBuild < VmMonitorWorker
      BUILD_TIMEOUT = 30.minutes

      def perform(task_id, user_id)
        super
      rescue Faraday::Error::ClientError, StandardError => e
        log_error(e)
        finish_task_error(:operation_error, exception: e)
      end

      def verify_vm_status
        case
        when failed_transactions.present? then finish_task_error(:failed_transaction)
        when remote_server_ready? then update_task_booted
        when build_timeout_expired? then finish_task_error(:build_timeout, timeout: BUILD_TIMEOUT)
        else update_task_to_monitor
        end
      end

      # TODO: handle error info when ip_address not set or disk_size
      def remote_server_ready?
        !@remote_server['locked'] &&
        @remote_server['built'] &&
        @remote_server['booted'] &&
        @remote_server['ip_addresses'].present? &&
        @remote_server['total_disk_size'].to_i > 1 &&
        pending_transactions.blank?
      end

      def build_timeout_expired?
        ((Time.now - @task.build_start).to_f / BUILD_TIMEOUT) > 1
      end

      def update_task_booted
        @task.update(
          build_end: Time.now,
          state: :to_clean
        )
      end
    end
  end
end
module Billing
  class BillingBandwidth
    attr_reader :server, :reason

    # reason possible values: :due_day, :destroy
    def initialize(server, reason = nil)
      @server = server
      @reason = reason
    end

    def bandwidth_usage
      zero =  last_invoice.blank? ? 0 : nil
      {
        billable: zero || billable_transfer_since_last_due_date_MB,
        free: zero || free_bandwidth_since_last_due_date_MB,
        hours: zero || hours_since_last_due_date
      }
    end

    def bandwidth_info
      zero =  last_invoice.blank? ? 0 : nil
      {
        used: zero || (data_transfer_since_last_due_date_MB / 1024.0).round(2),
        accrued: zero || (free_bandwidth_since_last_due_date_MB / 1024.0).round(2),
        forecasted: zero || forecasted_total_monthly_bandwidth_GB
      }
    end

    def billable_transfer_since_last_due_date_MB
      [data_transfer_since_last_due_date_MB - free_bandwidth_since_last_due_date_MB, 0].max
    end

    def data_transfer_since_last_due_date_MB
      (data_transfer_since_last_due_date_KB.to_f / 1024).ceil
    end

    def data_transfer_since_last_due_date_KB
      network_usage_since_last_due_date.inject(0) {|m,o| m+o[:data_received]+o[:data_sent]}
    end

    def network_usage_since_last_due_date
      total_network_usage.select {|data| data[:created_at] > last_due_date}
    end

    def total_network_usage
      ServerUsage.network_usages(server).map do |data|
        data.symbolize_keys!
        data[:created_at] = data[:created_at].to_time
        data
      end
    end

    def forecasted_total_monthly_bandwidth_GB
      [((free_bandwidth_since_last_due_date_MB + forecasted_free_bandwidth_MB) / 1024.0).round(2),
        server.bandwidth].min
    end

    def free_bandwidth_since_last_due_date_MB
      server.free_billing_bandwidth + free_bandwidth_since_last_invoice_MB
    end

    def free_bandwidth_since_last_invoice_MB
      (server.bandwidth.to_f * 1024 * hours_used_coefficient).round
    end

    def forecasted_free_bandwidth_MB
      (server.bandwidth.to_f * 1024 * hours_left_till_next_due_date.to_f / Account::HOURS_MAX).round
    end

    def hours_used_coefficient
      hours_since_last_invoice.to_f / Account::HOURS_MAX
    end

    def last_due_date
      @last_due_date ||= account.past_invoice_due(time_for_check)
    end

    def hours_left_till_next_due_date
      account.hours_till_next_invoice
    end

    def hours_since_last_due_date
      [hours_since_time(last_due_date), Account::HOURS_MAX].min
    end

    def hours_since_last_invoice
      return 0 if last_invoice.blank?
      [hours_since_time(last_invoice.created_at), Account::HOURS_MAX].min
    end

    def hours_since_time(time)
      ((Time.now - time) / 1.hour).ceil
    end

    def last_invoice
      server.last_generated_invoice_item
    end

    def account
      @account = Account.unscoped.where(deleted_at: nil, user_id: server.user_id).first
    end

    def time_for_check
      @time_for_check ||= (reason == :due_date) ? Time.now.change(hour: 0) : Time.now
    end
  end
end
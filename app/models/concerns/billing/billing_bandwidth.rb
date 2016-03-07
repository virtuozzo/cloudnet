module Billing
  class BillingBandwidth
    attr_reader :billable
    
    def initialize(billable)
      @billable = billable
    end
    
    def bandwidth_usage
      billable_free_MB(empty: last_invoice.blank?)
    end

    def billable_free_MB(empty: false)
      zero = empty ? 0 : nil
      binding.pry
      {
        billable: zero || billable_transfer_since_last_invoice_MB,
        free: zero || free_bandwidth_since_last_invoice_MB,
        hours: zero || hours_since_last_invoice
      }
    end
    
    def billable_transfer_since_last_invoice_MB
      [data_transfer_since_last_invoice_MB - free_bandwidth_since_last_invoice_MB, 0].max
    end
    
    def data_transfer_since_last_invoice_MB
      (data_transfer_since_last_invoice_KB.to_f / 1024).ceil
    end
    
    def data_transfer_since_last_invoice_KB
      network_usage_since_last_invoice.inject(0) {|m,o| m+o[:data_received]+o[:data_sent]}
    end
    
    def network_usage_since_last_invoice
      total_network_usage.select {|data| data[:created_at] > last_invoice.created_at}
    end
    
    def total_network_usage
      ServerUsage.network_usages(server).map do |data|
        data.symbolize_keys!
        data[:created_at] = data[:created_at].to_time
        data
      end
    end
    
    def free_bandwidth_since_last_invoice_MB
      @free_band_MB ||= (old_bandwidth.to_f * 1024 * hours_used_coefficient).round
    end

    def hours_used_coefficient
      hours_since_last_invoice.to_f / Account::HOURS_MAX
    end
    
    def hours_since_last_invoice
      @hours_last_inv ||= ((Time.now - last_invoice.created_at) / 1.hour).ceil
    end
    
    def last_invoice
      @last_invoice ||= server.last_generated_invoice_item
    end
    
    def server
      @server ||= billable.is_a?(ServerWizard) ?  server_from_wizard : billable
    end
    
    def server_from_wizard
      return billable unless billable.existing_server_id
      Server.find(billable.existing_server_id)
    end
    
    def old_bandwidth
      return 0 unless billable.is_a?(ServerWizard)
      billable.old_server_bandwidth
    end
  end
end
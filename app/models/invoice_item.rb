class InvoiceItem < ActiveRecord::Base
  include Metadata
  acts_as_paranoid

  belongs_to :invoice
  validates :invoice, presence: true

  def net_cost
    (read_attribute(:net_cost) || 0).round(-3)
  end

  def tax_cost
    if read_attribute(:tax_cost)
      read_attribute(:tax_cost).round(-3)
    else
      (net_cost * invoice.tax_rate).round(-3)
    end
  end

  def total_cost
    net_cost + tax_cost
  end

  def tax_code
    invoice.tax_code
  end

  def tax_rate
    invoice.tax_rate
  end

  def source
    @source ||= source_type.constantize.with_deleted.find(source_id) if source_type
  end

  def source=(source)
    self.source_type = source.class.to_s
    self.source_id   = source.id
  end

  def transactions
    if not invoice.payg?
      raise 'You can only call this method for PAYG invoices'
    end

    return ServerHourlyTransaction.with_deleted.without_duplicates.where(id: metadata[:transactions])
  end

  def increase_free_billing_bandwidth(old_bw)
    return unless source_type == "Server" # because of old bug, it can be 'ServerWizard'
    billing_manager = Billing::BillingBandwidth.new(source)
    free_bandwidth = (old_bw.to_f * 1024 * billing_manager.hours_used_coefficient).round
    bandwith_accrued = source.free_billing_bandwidth
    source.update_attribute(:free_billing_bandwidth, free_bandwidth + bandwith_accrued)
  end

  def billable_transactions
    if not invoice.payg?
      raise 'You can only call this method for PAYG invoices'
    end

    if invoice.transactions_capped?
      return self.transactions.billable
    else
      return self.transactions
    end
  end
end

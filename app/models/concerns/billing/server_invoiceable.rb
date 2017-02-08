require 'active_support/concern'

module Billing
  module ServerInvoiceable
    extend ActiveSupport::Concern

    def generate_invoice_item(hours, reason = false)
      ram  = ram_invoice_item(hours)
      cpu  = cpu_invoice_item(hours)
      disk = disk_invoice_item(hours)
      ip   = ip_invoice_item(hours)
      template = template_invoice_item(hours)
      bwf   = bandwidth_free_invoice_item(hours)
      bwp   = bandwidth_paid_invoice_item(reason) if reason
      adds = addons_invoice_items(hours)

      net_cost = ram[:net_cost] + cpu[:net_cost] + disk[:net_cost] + ip[:net_cost] + template[:net_cost] + adds.map { |a| a[:net_cost] }.sum
      net_cost += reason ? bwp[:net_cost] : 0

      description = "Server: #{name} (Hostname: #{hostname})"
      metadata = reason ? [ram, cpu, disk, bwf, bwp, ip, template] : [ram, cpu, disk, bwf, ip, template]
      adds.map {|addon| metadata << addon }
      { description: description, net_cost: net_cost, metadata: metadata, source: self }
    end

    def generate_payg_invoice_item(transactions)
      net_cost = transactions.billable.to_a.sum(&:cost)
      tx = transactions.map(&:id)
      description = "Server: #{name} (Hostname: #{hostname})"
      { description: description, net_cost: net_cost, metadata: { transactions: tx }, source: self }
    end

    def transactions(date_range = Date.today)
      server_hourly_transactions.with_deleted.where(created_at: date_range).without_duplicates
    end

    def generate_credit_item(hours)
      generate_invoice_item(hours)
    end

    def hourly_cost
      ram = ram_invoice_item(1)
      cpu = cpu_invoice_item(1)
      disk = disk_invoice_item(1)
      ip = ip_invoice_item(1)
      template = template_invoice_item(1)
      adds = addons_invoice_items(1)

      hourly = ram[:net_cost] + cpu[:net_cost] + disk[:net_cost] + ip[:net_cost] + template[:net_cost] + adds.map { |a| a[:net_cost] }.sum
    end

    def monthly_cost
      cost_for_hours(Account::HOURS_MAX)
    end

    def cost_for_hours(hours)
      item = generate_invoice_item(hours)
      item[:net_cost]
    end

    def ram_invoice_item(hours)
      {
        name: 'Memory',
        unit_cost: location.price_memory,
        units: memory,
        hours: hours,
        description: "#{memory} MB for #{hours} hours",
        net_cost: location.price_memory * memory.to_i * hours
      }
    end

    def cpu_invoice_item(hours)
      {
        name: 'CPU Cores',
        unit_cost: location.price_cpu,
        units: cpus,
        hours: hours,
        description: "#{cpus} Core(s) for #{hours} hours",
        net_cost: location.price_cpu * cpus.to_i * hours
      }
    end

    def disk_invoice_item(hours)
      {
        name: 'Disk Space',
        unit_cost: location.price_disk,
        units: disk_size,
        hours: hours,
        description: "#{disk_size} GB for #{hours} hours",
        net_cost: location.price_disk * disk_size.to_i * hours
      }
    end

    # Free monthly bandwidth is splited per usage hour
    def bandwidth_free_invoice_item(hours = Account::HOURS_MAX)
      bnd_prepaid = (bandwidth.to_f * 1024 * hours / Account::HOURS_MAX).round #MB
      {
        name: 'Prepaid Bandwidth',
        unit_cost: location.price_bw,
        units: bnd_prepaid,
        hours: hours,
        description: "#{bnd_prepaid}MB for next #{hours} hours",
        net_cost: 0.0
      }
    end

    # Additional bandwidth is post-paid
    # TODO: bandwidth price is taken from location, which can be changed after server creation
    def bandwidth_paid_invoice_item(reason)
      bandwidth_usage = BillingBandwidth.new(self, reason).bandwidth_usage
      {
        name: 'Additional Bandwidth',
        unit_cost: location.price_bw,
        units: bandwidth_usage[:billable],
        hours: bandwidth_usage[:hours],
        description: billable_bandwidth_description(bandwidth_usage),
        net_cost: location.price_bw * bandwidth_usage[:billable] # price in milicents / MB
      }
    end
    
    def addons_invoice_items(hours)
      invoice_items = []
      unless addons.nil?
        addons.each do |addon|
          invoice_items << addons_invoice_item(addon, hours)
        end
      end
      return invoice_items
    end
    
    def addons_invoice_item(addon, hours)
      {
        name: 'Add-on',
        unit_cost: addon.price,
        units: 1,
        hours: hours,
        description: "#{addon.name} for #{hours} hours",
        net_cost: addon.price * hours
      }
    end

    def billable_bandwidth_description(bandwidth_usage)
      billable_MB = bandwidth_usage[:billable]
      free_MB = bandwidth_usage[:free]
      hours_used = bandwidth_usage[:hours]
      "#{billable_MB}MB over free #{free_MB}MB for past #{hours_used} hours"
    end

    def ip_invoice_item(hours)
      additional_ips = [ip_addresses.to_i, 1].max - 1
      {
        name: 'IP Address',
        unit_cost: location.price_ip_address,
        units: additional_ips,
        description: "#{additional_ips} additional IP(s) for #{hours} hours",
        net_cost: location.price_ip_address.to_f * additional_ips * hours
      }
    end

    def template_invoice_item(hours)
      {
        name: 'Template',
        unit_cost: template.hourly_cost,
        units: 1,
        description: "#{template.name} for #{hours} hours",
        net_cost: template.hourly_cost * hours
      }
    end

    def charge_wallet
      @remaining_cost = calculate_amount_to_charge
      if @remaining_cost > 0
        payment_receipts_available = user.account.payment_receipts.with_remaining_cost
        raise "Insufficient funds" if @remaining_cost > payment_receipts_available.to_a.sum(&:remaining_cost)
        @payment_receipts_used = PaymentReceipt.charge_account(payment_receipts_available, @remaining_cost)
        user.account.create_activity :charge_payment_account, owner: user, params: { notes: @payment_receipts_used } unless @payment_receipts_used.empty?
      end
    rescue StandardError => e
      ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'ChargeWallet' })
      @build_errors.push('Could not charge your Wallet for the invoice amount. Please try again')
      user.account.create_activity(
        :charge_wallet_failed,
        owner: user,
        params: {
          invoice: @invoice.id,
          amount: @remaining_cost
        }
      )
      raise ServerWizard::WizardError
    end

    # Calculate how much the server is going to cost for the rest of the month and whether that cost
    # can be reduced with any remaining credit notes.
    def calculate_amount_to_charge
      # First calculate how much this server is going to cost for the rest of the month
      @invoice = Invoice.generate_prepaid_invoice([self], user.account)

      # Then we need to know if the user has any spare credit notes that will be reduced from the amount of the
      # Wallet charge we're about to make.
      credit_notes = user.account.credit_notes.with_remaining_cost
      # Deduct any unused value from the user's credit notes
      @notes_used = CreditNote.charge_account(credit_notes, @invoice.total_cost)
      # Make a note of this for posterity
      unless @notes_used.empty?
        user.account.create_activity(
          :charge_credit_account,
          owner: user,
          params: { notes: @notes_used }
        )
      end
      # Now, we finally have an amount to charge the billing card
      calculate_remaining_cost(@invoice.total_cost, @notes_used)
    end

    def charging_paperwork
      @invoice.invoice_items.first.source = @newly_built_server || @old_server_specs || self
      @invoice.increase_free_billing_bandwidth(@old_server_specs.try(:bandwidth))
      @invoice.save
      remaining = Invoice.milli_to_cents(@remaining_cost)
      if remaining > 0 && remaining < Invoice::MIN_CHARGE_AMOUNT
        @invoice.update(state: :partially_paid)
      else
        @invoice.update(state: :paid)
      end

      # Make a note of charges made for financial reports
      create_credit_note_charges if @notes_used.present?
      create_payment_receipt_charges if @payment_receipts_used.present?
      user.account.expire_wallet_balance
    end

    def create_payment_receipt_charges
      ChargeInvoicesTask.new(user, [@invoice], true).create_payment_receipt_charges(user.account, @invoice, @payment_receipts_used)
    end

    def create_credit_note_charges
      @notes_used.each do |k, v|
        source = CreditNote.find(k)
        Charge.create(source: source, invoice: @invoice, amount: v)
        user.account.create_activity(
          :credit_charge,
          owner: user,
          params: {
            invoice: @invoice.id,
            amount: v,
            credit_note: k
          }
        )
      end
    end

    def calculate_remaining_cost(total_cost, notes_used)
      total_cost - notes_used.values.sum
    end

    def create_credit_note_for_time_remaining
      if last_generated_invoice_item.present?
        credit_note = CreditNote.generate_credit_note([self], user.account, last_generated_invoice_item.invoice)
      else
        credit_note = CreditNote.generate_credit_note([self], user.account)
      end

      determine_vat_coupon_status(credit_note, last_generated_invoice_item)
      credit_note.save
      user.account.create_activity(
        :create_credit,
        owner: user,
        params: {
          credit_note: credit_note.id,
          amount: credit_note.total_cost
        }
      )
      credit_note
    end

    def last_generated_invoice_item
      return [] if id.nil? && @existing_server_id.nil?
      @last_generated_invoice_item ||= begin
        source_type = is_a?(ServerWizard) ? 'Server' : self.class.to_s
        InvoiceItem.where(
          source_type: source_type,
          source_id: id || @existing_server_id
        ).order(updated_at: :desc).first
      end
    end

    def determine_vat_coupon_status(credit_note, invoice_item)
      return unless invoice_item.present?
      invoice = invoice_item.invoice
      credit_note.vat_exempt = invoice.vat_exempt?
      credit_note.tax_code   = invoice.tax_code
      credit_note.coupon_id = invoice.coupon_id
    end

    def set_old_server_specs(old_server_specs)
      @old_server_specs = old_server_specs
    end
  end
end

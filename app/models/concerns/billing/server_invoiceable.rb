require 'active_support/concern'

module Billing
  module ServerInvoiceable
    extend ActiveSupport::Concern

    def generate_invoice_item(hours)
      ram  = ram_invoice_item(hours)
      cpu  = cpu_invoice_item(hours)
      disk = disk_invoice_item(hours)
      ip   = ip_invoice_item(hours)
      bw   = bandwidth_invoice_item
      template = template_invoice_item(hours)

      net_cost = ram[:net_cost] + cpu[:net_cost] + disk[:net_cost] + bw[:net_cost] + ip[:net_cost] + template[:net_cost]
      description = "Server: #{name} (Hostname: #{hostname})"
      { description: description, net_cost: net_cost, metadata: [ram, cpu, disk, bw, ip, template], source: self }
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

      hourly = ram[:net_cost] + cpu[:net_cost] + disk[:net_cost] + ip[:net_cost] + template[:net_cost]
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

    def bandwidth_invoice_item
      {
        name: 'Prepaid Bandwidth',
        unit_cost: location.price_bw,
        units: bandwidth,
        description: "#{bandwidth} GB for the month",
        net_cost: 0.0
      }
    end

    def ip_invoice_item(hours)
      {
        name: 'IP Address',
        unit_cost: location.price_ip_address,
        units: ip_addresses,
        description: "#{ip_addresses} IP(s) for #{hours} hours",
        net_cost: 0.0
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

    # Used by prepaid servers. When creating or editing a server, the first step is to calculate
    # the amount needed to be charged on card. If the user has any credit notes then they can be
    # used to reduce the charge.
    def auth_charge
      @charge = nil
      @billing_success = false

      @remaining_cost = calculate_amount_to_charge
      return unless Invoice.milli_to_cents(@remaining_cost) >= Invoice::MIN_CHARGE_AMOUNT

      @charge = prepare_charge_on_payment_gateway
    rescue Stripe::StripeError => e
      ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'CreateServerTask' })
      user.account.create_activity(
        :auth_charge_failed,
        owner: user,
        params: {
          card: card.id,
          amount: Invoice.milli_to_cents(@remaining_cost),
          reason: e.message
        }
      )
      @build_errors.push("Could not authorize charge using the card you've selected, please try again")
      raise ServerWizard::WizardError
    end

    # Calculate how much the server is going to cost for the rest of the month and whether that cost
    # can be reduced with any remaining credit notes.
    def calculate_amount_to_charge
      # First calculate how much this server is going to cost for the rest of the month
      @invoice = Invoice.generate_prepaid_invoice([self], user.account)

      # Then we need to know if the user has any spare credit notes that will reduced the amount of the
      # billing card charge we're about to make.
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

    def prepare_charge_on_payment_gateway
      charge = Payments.new.auth_charge(
        user.account.gateway_id,
        card.processor_token,
        Invoice.milli_to_cents(@remaining_cost)
      )
      user.account.create_activity(
        :auth_charge,
        owner: user,
        params: {
          card: card.id,
          amount: Invoice.milli_to_cents(@remaining_cost),
          charge_id: charge[:charge_id]
        }
      )
      charge
    end

    # Actually make the charge against a card.
    def make_charge
      if @charge.present?
        Payments.new.capture_charge(@charge[:charge_id], "Cloud.net Invoice #{@invoice.invoice_number}")
        user.account.create_activity(
          :capture_charge,
          owner: user,
          params: {
            card: card.id,
            charge: @charge[:charge_id]
          }
        )
      end

      charging_paperwork
    rescue StandardError => e
      # Clean up the lingering invoice and server
      @invoice.save
      @invoice.really_destroy!

      if @newly_built_server
        @newly_built_server.destroy
      else
        # Undo the server resize
        edit(
          server_wizard: {
            name: @old_server_specs.name,
            cpus: @old_server_specs.cpus,
            memory: @old_server_specs.memory,
            disk_size: @old_server_specs.disk_size
          }
        )
        request_server_edit
      end

      ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'CreateServerTask' })
      @build_errors.push('Could not charge your card for the invoice amount. Please try again')
      user.account.create_activity(
        :capture_charge_failed,
        owner: user,
        params: {
          card: card.id,
          charge: @charge[:charge_id]
        }
      )
      raise ServerWizard::WizardError
    end

    def charging_paperwork
      @invoice.invoice_items.first.source = self
      @invoice.save
      remaining = Invoice.milli_to_cents(@remaining_cost)
      if remaining > 0 && remaining < Invoice::MIN_CHARGE_AMOUNT
        @invoice.update(state: :partially_paid)
      else
        @invoice.update(state: :paid)
      end

      # Make a note of charges made for financial reports
      create_credit_note_charges
      create_card_charges if @charge.present?
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

    def create_card_charges
      Charge.create(
        source: card,
        invoice: @invoice,
        amount: @remaining_cost,
        reference: @charge[:charge_id]
      )
      user.account.create_activity(
        :card_charge,
        owner: user,
        params: {
          invoice: @invoice.id,
          amount: @remaining_cost,
          card: card.id
        }
      )
    end

    def calculate_remaining_cost(total_cost, notes_used)
      total_cost - notes_used.values.sum
    end

    def create_credit_note_for_time_remaining
      existing_invoice_item = InvoiceItem.where(
        source_type: self.class.to_s,
        source_id: id
      ).order(updated_at: :desc).first

      if existing_invoice_item.present?
        credit_note = CreditNote.generate_credit_note([self], user.account, existing_invoice_item.invoice)
      else
        credit_note = CreditNote.generate_credit_note([self], user.account)
      end

      determine_vat_coupon_status(credit_note, existing_invoice_item)
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

    def determine_vat_coupon_status(credit_note, invoice_item)
      return unless invoice_item.present?
      invoice = invoice_item.invoice
      credit_note.vat_exempt = invoice.vat_exempt?
      credit_note.tax_code   = invoice.tax_code
      credit_note.coupon_id = invoice.coupon_id
    end
  end
end

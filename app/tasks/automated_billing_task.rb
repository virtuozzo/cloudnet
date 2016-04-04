class AutomatedBillingTask < BaseTask
  def initialize(user, servers, hours = nil)
    super
    @servers = servers
    @user    = user
    @account = user.account
    @hours   = hours
  end

  def process
    card    = @account.primary_billing_card
    account = @user.account

    refresh_bandwidth
    invoice = Invoice.generate_prepaid_invoice(@servers, @account, @hours, :due_date)
    invoice.save!
    clear_free_bandwidth_accrued

    account.create_activity :automated_billing, owner: @user, params: { invoice: invoice.id, amount: invoice.total_cost }

    ChargeInvoicesTask.new(@user, [invoice], true).process
    invoice.reload
    send_auto_email(@user, invoice)
  end

  private

  def refresh_bandwidth
    @servers.each { |s| s.refresh_usage}
  end
  
  def clear_free_bandwidth_accrued
    Server.clear_free_bandwidth(@servers)
  end
  
  def send_auto_email(user, invoice)
    case invoice.state
    when :unpaid
      AutoBillingMailer.unpaid(user, invoice).deliver_now
    when :partially_paid
      AutoBillingMailer.partially_paid(user, invoice).deliver_now
    when :paid
      AutoBillingMailer.paid(user, invoice).deliver_now
    end
  end
end

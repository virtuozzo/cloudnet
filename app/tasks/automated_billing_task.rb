class AutomatedBillingTask < BaseTask
  def initialize(user, servers)
    super
    @servers = servers
    @user    = user
    @account = user.account
  end

  def process
    card    = @account.primary_billing_card
    account = @user.account

    invoice = Invoice.generate_prepaid_invoice(@servers, @account, Account::HOURS_MAX)
    invoice.save!
    account.create_activity :automated_billing, owner: @user, params: { invoice: invoice.id, amount: invoice.total_cost }

    ChargeInvoicesTask.new(@user, [invoice], true).process
    invoice.reload
    send_auto_email(@user, invoice)
  end

  private

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

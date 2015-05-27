class AutomatedPaygBillingTask < BaseTask
  def initialize(user, servers)
    super
    @servers = servers
    @user    = user
    @account = user.account
  end

  def process
    card    = @account.primary_billing_card
    account = @user.account

    invoice = Invoice.generate_payg_invoice(@servers, @account)
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
      AutoBillingMailer.payg_unpaid(user, invoice).deliver_now
    when :partially_paid
      AutoBillingMailer.payg_partially_paid(user, invoice).deliver_now
    when :paid
      AutoBillingMailer.payg_paid(user, invoice).deliver_now
    end
  end
end

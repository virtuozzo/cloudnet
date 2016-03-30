module PaygHelper
  def payg_options(account)
    @account = account
    @amounts = account.valid_top_up_amounts(request.remote_ip)
    options = @amounts.map { |amount| ["$#{amount} USD", amount] }
    options_for_select options, @amounts.first
  end

  def add_option_to_pay_off_balance
    remaining_balance = (Invoice.milli_to_cents @account.remaining_balance) / 100.0
    return false unless remaining_balance > 0
    remaining_balance = format '%.2f', remaining_balance
    @amounts.unshift remaining_balance
  end
end

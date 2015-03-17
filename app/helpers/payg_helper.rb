module PaygHelper
  def payg_options
    amounts = Payg::VALID_TOP_UP_AMOUNTS
    options_for_select(amounts.map { |amount| ["$#{amount} USD", amount] }, amounts.first)
  end
end

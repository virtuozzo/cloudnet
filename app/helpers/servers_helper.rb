module ServersHelper
  def dropdown_class(server)
    'disabled' if server.state != :on && server.state != :off
  end

  def server_cost(without_vat, with_vat, precision = 2)
    if current_user.account.billing_country.present?
      if current_user.account.vat_exempt?
        pretty_total(without_vat, '$', precision)
      else
        "#{pretty_total(with_vat, '$', precision)} (EU VAT inclusive)"
      end
    else
      "#{pretty_total(without_vat, '$', precision)} (#{pretty_total(with_vat)} with EU VAT)"
    end
  end
end

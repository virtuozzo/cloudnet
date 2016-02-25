module ServerWizardsHelper
  def billing_cost(without_vat, with_vat, currency = '$', precision = 2)
    if current_user.account.billing_country.present?
      if current_user.account.vat_exempt?
        pretty_total(without_vat, currency, precision)
      else
        "#{pretty_total(with_vat, currency, precision)} (EU VAT inclusive)"
      end
    else
      "#{pretty_total(without_vat, currency, precision)} (#{pretty_total(with_vat, currency, precision)} with EU VAT if applicable)"
    end
  end

  def location_cache_key
    max_updated_at = Location.maximum(:updated_at).try(:utc).try(:to_s, :number) || 0
    "locations/all-#{max_updated_at}"
  end
end

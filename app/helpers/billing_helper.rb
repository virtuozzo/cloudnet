module BillingHelper
  def country_name(code)
    return 'Unknown' unless code.present?
    IsoCountryCodes.find(code).name
  end
end

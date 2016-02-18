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
  
  # sliders when
  # no vps AND no package choosen AND values in url params
  def activate_slider_tab
    @server or
    (!@wizard_object.location.budget_vps and !@wizard_object.package_matched and @wizard_object.params_values?)
  end
  
  def provisioner_role_options(selected)
    options_for_select(Server::PROVISIONER_ROLES.map {|role| [role.camelize, role]}, selected)
  end
end

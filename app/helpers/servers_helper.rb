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

  def dummy_packages
    dummy_packages = [{id: 1, cpus: 1, memory: 512,  disk_size: 20, bandwidth: 100},
      {id: 2, cpus: 2, memory: 1024, disk_size: 40, bandwidth: 100},
      {id: 3, cpus: 4, memory: 2048, disk_size: 60, bandwidth: 100}].to_json
    JSON.parse(dummy_packages, object_class: OpenStruct)
  end

  def activate_apps_tab?
    false
  end

end

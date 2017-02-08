json.extract!(
  server,
  :id,
  :name,
  :hostname,
  :state,
  :os,
  :os_distro,
  :memory,
  :root_password,
  :cpus,
  :disk_size,
  :bandwidth,
  :ip_addresses,
  :primary_ip_address,
  :provisioner_role
)

json.bandwidth_info Billing::BillingBandwidth.new(server).bandwidth_info

json.hourly_cost server.hourly_cost / Invoice::MILLICENTS_IN_DOLLAR
json.monthly_cost server.monthly_cost / Invoice::MILLICENTS_IN_DOLLAR

json.created_at server.created_at.iso8601
json.updated_at server.updated_at.iso8601

json.location do
  json.extract! server.location, :id, :latitude, :longitude, :provider, :country, :city, :country_name, :ssd_disks
end

json.template do
  json.extract! server.template, :id, :name, :os_type, :os_distro, :location_id, :min_disk, :min_memory, :hourly_cost
end

json.server_ip_addresses server.server_ip_addresses, :address, :primary
json.ips_available server.can_add_ips?

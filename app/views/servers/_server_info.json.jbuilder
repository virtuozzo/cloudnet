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
  :bandwidth
)

json.created_at server.created_at.iso8601
json.updated_at server.updated_at.iso8601

json.location do
  json.extract! server.location, :id, :latitude, :longitude, :provider, :country, :city, :country_name, :ssd_disks
end

json.template do
  json.extract! server.template, :id, :name, :os_type, :os_distro, :location_id, :min_disk, :min_memory, :hourly_cost
end

json.key_format! camelize: :lower
json.array! @locations do |loc|
  json.extract! loc, :id, :city, :country, :country_name, :provider, :provider_link,
                     :cloud_index, :price_cpu, :price_memory, :price_disk,
                     :budget_vps, :ssd_disks, :latitude, :longitude, :photo_ids,
                     :summary
  json.indices loc.indices, :created_at, :index_uptime, :cloud_index, :index_cpu, 
                            :index_iops, :index_bandwidth
  json.certificates loc.certificates do |cert|
    json.avatar cert.avatar.url
    json.id cert.id
  end
    json.region loc.region
end
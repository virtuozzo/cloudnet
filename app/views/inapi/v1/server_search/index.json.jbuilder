json.key_format! camelize: :lower
json.array! @locations do |loc|
  json.extract! loc, :id, :city, :country, :country_name, :provider, :provider_link,
                     :cloud_index, :price_cpu, :price_memory, :price_disk,
                     :budget_vps, :ssd_disks, :latitude, :longitude, :photo_ids,
                     :summary, :inclusive_bandwidth
  json.indices loc.indices do |i|
     json.date i.created_at
     json.cloud_index i.cloud_index
     json.index_cpu i.index_cpu
     json.index_iops i.index_iops
     json.index_bandwidth i.index_bandwidth
  end
  json.certificates loc.certificates do |cert|
    json.avatar cert.avatar.url
    json.id cert.id
  end
  json.uptimes loc.frontend_uptimes
  json.region loc.region
end
json.extract! location, :id, :latitude, :longitude, :provider, :provider_link, :country, :city, :country_name, :photo_ids, :budget_vps, :inclusive_bandwidth, :ssd_disks
json.available_resources do
  json.extract! location, :memory, :cpu, :disk_size
end

json.prices do
  json.extract! location, :price_memory, :price_cpu, :price_disk, :price_bw, :price_ip_address
end

json.index_scores do
  scores = location.index_scores
  json.cpu scores[:cpu]
  json.bandwidth scores[:bandwidth]
  json.iops scores[:iops]
end

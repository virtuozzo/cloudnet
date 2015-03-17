templates.each do |kv|
  json.set! kv[0] do
    json.array! kv[1] do |template|
      json.extract! template, :id, :name, :os_type, :os_distro, :location_id, :min_disk, :min_memory, :hourly_cost
    end
  end
end

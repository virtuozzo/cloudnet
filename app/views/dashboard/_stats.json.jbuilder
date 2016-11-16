json.stats do
  [:memory, :disk_size, :cpus, :bandwidth].each do |item|
    json.set! item do
      json.usage stats[item][:usage]
      json.split do
        json.array! stats[item][:split].each do |server|
          json.partial! 'servers/server_info', server: server
          json.usage server.send(item)
        end
      end
      json.unit stats[item][:unit]
    end
  end

  json.tickets do
    json.array! stats[:tickets] do |ticket|
      json.extract! ticket, :id, :subject, :status, :reference
      json.created_at ticket.created_at.iso8601
      json.updated_at ticket.updated_at.iso8601
    end
  end

  json.cpu_stats do
    json.array! stats[:cpu_stats]
  end
end

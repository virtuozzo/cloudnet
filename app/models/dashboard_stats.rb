class DashboardStats
  def self.gather_stats(user, servers)
    stats = {
      memory:    { usage: 0, split: [], unit: 'MB' },
      cpus:      { usage: 0, split: [], unit: 'Cores' },
      disk_size: { usage: 0, split: [], unit: 'GB' },
      bandwidth: { usage: 0, split: [], unit: 'GB' },
      tickets:   user.tickets.order(updated_at: :desc).limit(5),
      cpu_stats: []
    }

    include_split = servers.size <= 10
    servers.each do |server|
      add_server_stat(stats[:memory], server, :memory, include_split)
      add_server_stat(stats[:cpus], server, :cpus, include_split)
      add_server_stat(stats[:disk_size], server, :disk_size, include_split)
      add_server_stat(stats[:bandwidth], server, :bandwidth, include_split)
    end
    servers.last(10).each do |server|
      add_cpu_stats(stats, server)
    end

    stats
  end

  def self.gather_costs(user, servers)
    hours = Account::HOURS_MAX

    costs = {
      memory:    { monthly: 0 },
      disk_size: { monthly: 0 },
      cpus:      { monthly: 0 },
      bandwidth: { monthly: 0 }
    }

    servers.each do |server|
      costs[:memory][:monthly]    += server.ram_invoice_item(hours)[:net_cost]
      costs[:cpus][:monthly]      += server.cpu_invoice_item(hours)[:net_cost]
      costs[:disk_size][:monthly] += server.disk_invoice_item(hours)[:net_cost]
      #costs[:bandwidth][:monthly] += server.bandwidth_free_invoice_item[:net_cost]
    end

    costs
  end

  private

  def self.add_server_stat(hash, server, stat, include_split)
    usage = server.send(stat)
    hash[:usage] += usage
    hash[:split] << server if include_split
  end

  def self.add_cpu_stats(stats, server)
    stats[:cpu_stats] << { id: server.id, name: server.name, cpu_usages: ServerUsage.cpu_usages(server, 1) }
  end
end

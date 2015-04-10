task calculate_per_location_costs: :environment do
  year = ENV['YEAR'].to_i
  month = ENV['MONTH'].to_i

  # Method 1: By server usage
  # Get all servers that were created in the given month
  servers_by_location = Server.with_deleted
    .where('extract(year from created_at) = ?', year)
    .where('extract(month from created_at) = ?', month)
    .group_by(&:location)

  servers_by_location.each do |location|
    provider = location[0]
    servers = location[1]
    provider_total_costs = 0

    servers.each do |server|
      # Only calculate the amount of time the server existed in the given month
      end_time = server.deleted_at || Date.new(year, month).end_of_month.to_time
      hours = (end_time - server.created_at) / 3600
      # Calculate how much the server cost for the given month
      cost_for_month = server.generate_invoice_item(hours)[:net_cost]
      # Add to the providers total costs for this month
      provider_total_costs += cost_for_month
    end

    puts "#{provider}: #{Invoice.pretty_total provider_total_costs}"
  end
end

require 'csv'

class CostAnalysisReport < BaseTask
  def generate
    columns = %w(server_id server_name ip_address state suspended cpus memory disk bandwidth ips location email user_suspended coupon_code coupon_percentage forecasted_rev market_cost)
    
    CSV.generate do |csv|
      csv << columns
      Server.find_each do |server|
        user = server.user
        coupon = user.account.coupon rescue nil
        coupon_code = coupon.present? ? coupon.coupon_code : nil
        coupon_percentage = coupon.present? ? coupon.percentage : 0
        row = [server.id, server.name, server.primary_ip_address, server.state, server.suspended, server.cpus, server.memory, server.disk_size, server.bandwidth, server.ip_addresses, server.location.to_s, user.email, user.suspended, coupon_code, coupon_percentage]
        begin
          price_per_month = server.forecasted_revenue / Invoice::MILLICENTS_IN_DOLLAR rescue nil
          remote_server = RemoteServer.new(server.identifier).show
          market_cost_per_hour = remote_server["price_per_hour"].to_f if remote_server
          market_cost_per_month = (market_cost_per_hour * 720.0).round(2) if market_cost_per_hour # Cost per 30 days
          row.concat([price_per_month, market_cost_per_month])
        rescue => e
          p e
        ensure
          csv << row
        end
      end
    end
  end
end

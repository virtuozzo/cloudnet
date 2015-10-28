class ForecastedRevenue
  include Sidekiq::Worker
  sidekiq_options unique: true
  
  def perform
    Location.all.each do |location|
      location.servers.each do |s|
        month_price = server_monthly_price(s, location)
        discount = (1 - coupon_percentage(s.user.account.try(:coupon))).round(3)
        discounted_price = (month_price * discount).round
        s.update_attribute(:forecasted_rev, discounted_price)
      end
    end
  end
  
  def coupon_percentage(coupon)
    if coupon.present? then coupon.percentage_decimal else 0 end
  end
  
  def server_monthly_price(server, location)
    h_price = location.hourly_price(server.memory, server.cpus, server.disk_size)
    (h_price * Account::HOURS_MAX).round
  end
end
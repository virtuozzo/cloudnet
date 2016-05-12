class SetExpiryCouponDates < ActiveRecord::Migration
  def up
    Coupon.update_all(expiry_date: Date.today + 25.years)
  end

  def down
    Coupon.update_all(expiry_date: nil)
  end
end

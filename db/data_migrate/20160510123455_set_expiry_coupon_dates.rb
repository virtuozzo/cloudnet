class SetExpiryCouponDates < ActiveRecord::Migration
  def up
    Coupon.update_all(expiry_date: Date.today + 5.years)
  end

  def down
    Coupon.update_all(expiry_date: nil)
  end
end

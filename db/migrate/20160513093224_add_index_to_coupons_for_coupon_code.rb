class AddIndexToCouponsForCouponCode < ActiveRecord::Migration
  def change
    add_index(:coupons, :coupon_code, unique: true)
  end
end

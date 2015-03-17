class AddCouponCodesToAccounts < ActiveRecord::Migration
  def change
    add_reference :accounts, :coupon, index: true
    add_column :accounts, :coupon_activated_at, :datetime
  end
end

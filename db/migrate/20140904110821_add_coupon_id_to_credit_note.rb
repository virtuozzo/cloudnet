class AddCouponIdToCreditNote < ActiveRecord::Migration
  def change
    add_column :credit_notes, :coupon_id, :integer, index: true
  end
end

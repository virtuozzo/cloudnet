class AddCouponIdToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :coupon_id, :integer, index: true
  end
end

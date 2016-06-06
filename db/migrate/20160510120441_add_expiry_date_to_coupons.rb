class AddExpiryDateToCoupons < ActiveRecord::Migration
  def change
    add_column :coupons, :expiry_date, :date
  end
end

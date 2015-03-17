class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.string :coupon_code
      t.boolean :active, default: true
      t.integer :percentage, default: 20
      t.integer :duration_months, default: 3

      t.timestamps
    end
  end
end

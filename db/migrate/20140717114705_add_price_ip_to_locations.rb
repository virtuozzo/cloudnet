class AddPriceIpToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :price_ip_address, :decimal, default: 0
  end
end

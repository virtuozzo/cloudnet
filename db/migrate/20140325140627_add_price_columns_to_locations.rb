class AddPriceColumnsToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :price_memory, :integer, default: 0
    add_column :locations, :price_disk, :integer, default: 0
    add_column :locations, :price_cpu, :integer, default: 0
    add_column :locations, :price_bw, :integer, default: 0
  end
end

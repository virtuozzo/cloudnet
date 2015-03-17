class MakePriceColumnsDecimalsInLocations < ActiveRecord::Migration
  def change
    change_column :locations, :price_memory, :decimal, default: 0
    change_column :locations, :price_disk, :decimal, default: 0
    change_column :locations, :price_cpu, :decimal, default: 0
    change_column :locations, :price_bw, :decimal, default: 0
  end
end

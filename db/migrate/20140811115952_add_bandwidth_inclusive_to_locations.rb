class AddBandwidthInclusiveToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :inclusive_bandwidth, :integer, default: 100
  end
end

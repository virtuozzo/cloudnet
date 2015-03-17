class AddMaxIndicesToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :max_index_cpu, :integer, default: 0
    add_column :locations, :max_index_iops, :integer, default: 0
    add_column :locations, :max_index_bandwidth, :integer, default: 0
    add_column :locations, :max_index_uptime, :float, default: 0.0
  end
end

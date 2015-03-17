class RemoveIndicesFromLocations < ActiveRecord::Migration
  def change
    remove_column :locations, :index_cpu
    remove_column :locations, :index_iops
    remove_column :locations, :index_bandwidth
  end
end

class AddCloudIndexesToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :index_cpu, :integer, default: 0
    add_column :locations, :index_iops, :integer, default: 0
    add_column :locations, :index_bandwidth, :integer, default: 0
  end
end

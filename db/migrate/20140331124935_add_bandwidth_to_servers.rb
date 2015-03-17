class AddBandwidthToServers < ActiveRecord::Migration
  def change
    add_column :servers, :bandwidth, :integer, default: 0
  end
end

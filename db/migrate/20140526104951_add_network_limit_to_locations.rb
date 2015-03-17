class AddNetworkLimitToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :network_limit, :integer
  end
end

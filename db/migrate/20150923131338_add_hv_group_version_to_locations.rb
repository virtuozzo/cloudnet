class AddHvGroupVersionToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :hv_group_version, :string
  end
end

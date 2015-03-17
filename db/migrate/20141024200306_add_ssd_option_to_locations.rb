class AddSsdOptionToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :ssd_disks, :boolean, default: false
  end
end

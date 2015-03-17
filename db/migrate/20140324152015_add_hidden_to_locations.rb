class AddHiddenToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :hidden, :boolean, default: true
  end
end

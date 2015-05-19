class AddRegionRefToLocations < ActiveRecord::Migration
  def change
    add_reference :locations, :region, index: true
    add_foreign_key :locations, :regions
  end
end

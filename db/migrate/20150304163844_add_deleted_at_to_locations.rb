class AddDeletedAtToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :deleted_at, :timestamp
  end
end

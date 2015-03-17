class AddPhotoIdsToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :photo_ids, :string
  end
end

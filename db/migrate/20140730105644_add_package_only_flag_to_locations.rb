class AddPackageOnlyFlagToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :package_only, :boolean, default: false
  end
end

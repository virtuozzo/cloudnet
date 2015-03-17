class ChangeNameToProviderOnLocations < ActiveRecord::Migration
  def change
    rename_column :locations, :name, :provider
  end
end

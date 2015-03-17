class RenameDiskToDiskSizeInServerWizardsAndLocations < ActiveRecord::Migration
  def change
    rename_column :server_wizards, :disk, :disk_size
    rename_column :locations, :disk, :disk_size
  end
end

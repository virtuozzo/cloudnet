class AddAddonInfoToServerAddons < ActiveRecord::Migration
  def change
    add_column :server_addons, :addon_info, :text
  end
end

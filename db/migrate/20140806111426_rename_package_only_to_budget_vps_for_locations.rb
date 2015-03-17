class RenamePackageOnlyToBudgetVpsForLocations < ActiveRecord::Migration
  def change
    rename_column :locations, :package_only, :budget_vps
  end
end

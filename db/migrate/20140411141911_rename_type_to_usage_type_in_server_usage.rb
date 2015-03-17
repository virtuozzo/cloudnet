class RenameTypeToUsageTypeInServerUsage < ActiveRecord::Migration
  def change
    rename_column :server_usages, :type, :usage_type
  end
end

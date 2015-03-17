class AddDeletedAtToServerUsages < ActiveRecord::Migration
  def change
    add_column :server_usages, :deleted_at, :datetime
  end
end

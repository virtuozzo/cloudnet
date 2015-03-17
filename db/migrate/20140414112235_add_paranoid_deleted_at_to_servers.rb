class AddParanoidDeletedAtToServers < ActiveRecord::Migration
  def change
    remove_column :servers, :deleted_at
    add_column :servers, :deleted_at, :datetime
    add_index :servers, :deleted_at
  end
end

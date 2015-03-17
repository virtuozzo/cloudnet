class AddDeletedAtToServers < ActiveRecord::Migration
  def change
    add_column :servers, :deleted_at, :datetime
  end
end

class FixColumnNameInApiKeys < ActiveRecord::Migration
  def change
    rename_column :api_keys, :key, :encrypted_key
  end
  
  execute "DELETE FROM api_keys;"
end

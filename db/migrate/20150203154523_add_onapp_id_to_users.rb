class AddOnappIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :onapp_id, :string
  end
end

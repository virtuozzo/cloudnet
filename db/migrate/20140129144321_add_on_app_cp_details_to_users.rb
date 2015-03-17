class AddOnAppCpDetailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :onapp_user, :string
    add_column :users, :onapp_email, :string
    add_column :users, :encrypted_onapp_password, :string
  end
end

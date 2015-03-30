class AddAddressFieldsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :address1, :string
    add_column :accounts, :address2, :string
    add_column :accounts, :city, :string
    add_column :accounts, :country, :string
    add_column :accounts, :postal, :string
  end
end

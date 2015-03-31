class AddMoreAddressFieldsToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :address3, :string
    add_column :accounts, :address4, :string
    add_column :accounts, :company_name, :string
    remove_column :accounts, :city, :string
  end
end

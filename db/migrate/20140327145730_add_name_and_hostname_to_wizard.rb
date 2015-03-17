class AddNameAndHostnameToWizard < ActiveRecord::Migration
  def change
    add_column :wizards, :name, :string
    add_column :wizards, :hostname, :string
  end
end

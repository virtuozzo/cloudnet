class AddLocationIdtoWizard < ActiveRecord::Migration
  def change
    add_column :wizards, :location_id, :integer
    add_column :wizards, :location_name, :string
  end
end

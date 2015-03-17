class RenameWizardToServerWizard < ActiveRecord::Migration
  def change
    rename_table :wizards, :server_wizards
  end
end

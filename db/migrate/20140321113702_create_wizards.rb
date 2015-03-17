class CreateWizards < ActiveRecord::Migration
  def change
    create_table :wizards do |t|

      t.timestamps
    end
  end
end

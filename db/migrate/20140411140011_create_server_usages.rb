class CreateServerUsages < ActiveRecord::Migration
  def change
    create_table :server_usages do |t|
      t.references :server, index: true
      t.text :usages
      t.string :type

      t.timestamps
    end
  end
end

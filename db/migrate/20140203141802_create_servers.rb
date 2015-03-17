class CreateServers < ActiveRecord::Migration
  def change
    create_table :servers do |t|
      t.string :identifier
      t.string :name
      t.string :hostname
      t.string :state

      t.timestamps
    end
  end
end

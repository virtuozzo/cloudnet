class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :reference
      t.datetime :log_date
      t.string :action
      t.string :status
      t.references :server

      t.timestamps
    end
  end
end

class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.string :subject
      t.text :body
      t.text :server
      t.references :user, index: true

      t.timestamps
    end
  end
end

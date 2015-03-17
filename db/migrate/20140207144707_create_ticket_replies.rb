class CreateTicketReplies < ActiveRecord::Migration
  def change
    create_table :ticket_replies do |t|
      t.text :reply
      t.references :ticket, index: true
      t.string :sender

      t.timestamps
    end
  end
end

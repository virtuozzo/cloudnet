class AddExternalRefToTicketReplies < ActiveRecord::Migration
  def change
    add_column :ticket_replies, :reference, :string
  end
end

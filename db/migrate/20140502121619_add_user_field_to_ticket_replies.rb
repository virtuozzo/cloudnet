class AddUserFieldToTicketReplies < ActiveRecord::Migration
  def change
    add_reference :ticket_replies, :user, index: true
  end
end

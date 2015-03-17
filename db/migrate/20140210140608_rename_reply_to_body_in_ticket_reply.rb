class RenameReplyToBodyInTicketReply < ActiveRecord::Migration
  def change
    rename_column :ticket_replies, :reply, :body
  end
end

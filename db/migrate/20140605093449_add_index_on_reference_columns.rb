class AddIndexOnReferenceColumns < ActiveRecord::Migration
  def change
    add_index :server_events, :reference
    add_index :servers, :identifier
    add_index :tickets, :reference
    add_index :ticket_replies, :reference
    add_index :locations, :hv_group_id
  end
end

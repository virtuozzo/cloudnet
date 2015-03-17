class ChangeServersFromTextToReferences < ActiveRecord::Migration
  def change
    remove_column :tickets, :server
    add_reference :tickets, :server, index: true, default: -1
  end
end

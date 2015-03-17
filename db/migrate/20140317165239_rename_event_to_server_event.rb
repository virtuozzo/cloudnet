class RenameEventToServerEvent < ActiveRecord::Migration
  def change
    rename_table :events, :server_events
  end
end

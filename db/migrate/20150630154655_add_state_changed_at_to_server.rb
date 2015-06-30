class AddStateChangedAtToServer < ActiveRecord::Migration
  def change
    add_column :servers, :state_changed_at, :time
  end
end

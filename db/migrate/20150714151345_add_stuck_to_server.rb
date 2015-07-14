class AddStuckToServer < ActiveRecord::Migration
  def change
    add_column :servers, :stuck, :boolean, default: false
  end
end

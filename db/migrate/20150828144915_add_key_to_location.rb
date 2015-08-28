class AddKeyToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :key, :string
  end
end

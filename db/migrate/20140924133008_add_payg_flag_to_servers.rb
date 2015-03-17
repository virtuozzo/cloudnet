class AddPaygFlagToServers < ActiveRecord::Migration
  def change
    add_column :servers, :payg, :boolean, default: false
  end
end

class AddServerLimitFieldsToUser < ActiveRecord::Migration
  class User < ActiveRecord::Base
  end

  def change
    add_column :users, :vm_max, :integer
    add_column :users, :memory_max, :integer
    add_column :users, :cpu_max, :integer
    add_column :users, :storage_max, :integer
    add_column :users, :bandwidth_max, :integer

    User.reset_column_information
    reversible do |dir|
      dir.up { User.update_all vm_max: 2, memory_max: 1536, cpu_max: 3, storage_max: 30, bandwidth_max: 50 }
    end
  end
end

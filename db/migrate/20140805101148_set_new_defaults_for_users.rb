class SetNewDefaultsForUsers < ActiveRecord::Migration
  def change
    change_column_default :users, :vm_max, 6
    change_column_default :users, :memory_max, 4096
    change_column_default :users, :cpu_max, 4
    change_column_default :users, :storage_max, 120
    change_column_default :users, :bandwidth_max, 1024

    reversible do |dir|
      dir.up { User.update_all(vm_max: 6,  memory_max: 4096, cpu_max: 4, storage_max: 120, bandwidth_max: 1024) }
    end
  end
end

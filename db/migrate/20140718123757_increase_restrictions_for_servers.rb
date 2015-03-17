class IncreaseRestrictionsForServers < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up { User.update_all(vm_max: 6,  memory_max: 4096, cpu_max: 4, storage_max: 120, bandwidth_max: 1024) }
    end
  end
end

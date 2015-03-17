class UpdateMemoryMaxForUser < ActiveRecord::Migration
  def change
    change_column_default :users, :memory_max, 8192

    reversible do |dir|
      dir.up { User.update_all(memory_max: 8192) }
    end
  end
end

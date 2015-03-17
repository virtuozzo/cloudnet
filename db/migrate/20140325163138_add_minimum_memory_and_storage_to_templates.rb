class AddMinimumMemoryAndStorageToTemplates < ActiveRecord::Migration
  def change
    add_column :templates, :min_memory, :integer, default: 0
    add_column :templates, :min_disk, :integer, default: 0
  end
end

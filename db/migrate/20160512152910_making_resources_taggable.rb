class MakingResourcesTaggable < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :label
      t.timestamps
    end
    
    create_table :taggings do |t|
      t.integer :tag_id
      t.integer :taggable_id
      t.string  :taggable_type
      t.timestamps
    end
    
    add_index(:taggings, [:tag_id, :taggable_id, :taggable_type], unique: true)
    add_index(:tags, :label, unique: true)
  end
end

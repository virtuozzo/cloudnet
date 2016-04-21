class CreateUserServerCounts < ActiveRecord::Migration
  def change
    create_table :user_server_counts do |t|
      t.references :user, index: true
      t.date :date
      t.integer :servers_count

      t.timestamps null: false
    end
    add_foreign_key :user_server_counts, :users
    add_index :user_server_counts, [:user_id, :date], unique: true, name: 'count_for_user_at_day'
    
    add_column :users, :vm_count_tag, :string
    add_column :users, :vm_count_trend, :string
  end
end

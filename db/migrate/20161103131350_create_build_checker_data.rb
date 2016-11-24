class CreateBuildCheckerData < ActiveRecord::Migration
  def change
    create_table :build_checker_data do |t|
      t.references :template, null: false, index: true
      t.references :location, null: false, index: true
      t.datetime :start_after
      t.datetime :build_start
      t.datetime :build_end
      t.integer :build_result, null: false, default: 0, index: true
      t.boolean :scheduled
      t.integer :state, null: false, default: 0, index: true
      t.datetime :delete_queued_at
      t.datetime :deleted_at, index: true
      t.string :onapp_identifier
      t.datetime :notified_at
      t.string :error

      t.timestamps null: false
    end
    add_foreign_key :build_checker_data, :templates
    add_foreign_key :build_checker_data, :locations

    add_index :build_checker_data, [:template_id, :scheduled], unique: true
    add_index :build_checker_data, [:scheduled, :start_after], where: "(scheduled IS TRUE)"
    add_index :build_checker_data, :scheduled, where: "(scheduled IS TRUE)"
  end
end

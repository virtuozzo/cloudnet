class AddBuildCheckerToTemplates < ActiveRecord::Migration
  def change
    add_column :templates, :build_checker, :boolean, null: false, default: false, index: true
    add_index :templates, [:build_checker, :location_id], where: "(build_checker IS TRUE)"
  end
end

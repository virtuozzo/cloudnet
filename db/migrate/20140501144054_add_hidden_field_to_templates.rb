class AddHiddenFieldToTemplates < ActiveRecord::Migration
  def change
    add_column :templates, :hidden, :boolean, default: false
  end
end

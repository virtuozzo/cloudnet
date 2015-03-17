class RenamePriceToHourlyCostInTemplates < ActiveRecord::Migration
  def change
    rename_column :templates, :price, :hourly_cost
  end
end

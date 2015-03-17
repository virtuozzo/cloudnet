class MakeHourlyCostDefaultToZeroOnTemplates < ActiveRecord::Migration
  def change
  	change_column :templates, :hourly_cost, :integer, :default => true
  end
end

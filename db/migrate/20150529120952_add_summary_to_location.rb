class AddSummaryToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :summary, :text
  end
end

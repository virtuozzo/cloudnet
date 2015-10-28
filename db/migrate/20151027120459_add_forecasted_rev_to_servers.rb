class AddForecastedRevToServers < ActiveRecord::Migration
  def change
    add_column :servers, :forecasted_rev, :decimal, default: 0
  end
end

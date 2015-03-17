class ConvertBandwidthFromIntegerToDecimal < ActiveRecord::Migration
  def change
    change_column :servers, :bandwidth, :decimal
  end
end

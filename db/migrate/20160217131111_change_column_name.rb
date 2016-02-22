class ChangeColumnName < ActiveRecord::Migration
  def change
    rename_column :servers, :in_provision, :no_refresh
  end
end

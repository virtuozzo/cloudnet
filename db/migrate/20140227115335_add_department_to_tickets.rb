class AddDepartmentToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :department, :string
  end
end

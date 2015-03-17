class AddReferenceToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :reference, :string
  end
end

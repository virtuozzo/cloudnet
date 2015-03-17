class AddChargeReferenceToCharge < ActiveRecord::Migration
  def change
    add_column :charges, :reference, :string
  end
end

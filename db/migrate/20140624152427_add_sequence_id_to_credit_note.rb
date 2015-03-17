class AddSequenceIdToCreditNote < ActiveRecord::Migration
  def change
    add_column :credit_notes, :sequence_id, :integer
  end
end

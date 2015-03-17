class RenameSequenceIdToSequentialIdInCreditNote < ActiveRecord::Migration
  def change
    rename_column :credit_notes, :sequence_id, :sequential_id
  end
end

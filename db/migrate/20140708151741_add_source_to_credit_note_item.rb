class AddSourceToCreditNoteItem < ActiveRecord::Migration
  def change
    add_column :credit_note_items, :source_id, :integer
    add_column :credit_note_items, :source_type, :string
  end
end

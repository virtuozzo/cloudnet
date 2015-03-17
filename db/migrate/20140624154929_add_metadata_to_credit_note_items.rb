class AddMetadataToCreditNoteItems < ActiveRecord::Migration
  def change
    add_column :credit_note_items, :metadata, :string
  end
end

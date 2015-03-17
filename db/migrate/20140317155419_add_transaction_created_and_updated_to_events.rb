class AddTransactionCreatedAndUpdatedToEvents < ActiveRecord::Migration
  def change
    rename_column :events, :log_date, :transaction_created
    add_column :events, :transaction_updated, :datetime
  end
end

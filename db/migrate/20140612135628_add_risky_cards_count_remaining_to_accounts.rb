class AddRiskyCardsCountRemainingToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :risky_cards_remaining, :integer, default: 3
  end
end

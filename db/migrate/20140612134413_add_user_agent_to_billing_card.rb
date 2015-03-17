class AddUserAgentToBillingCard < ActiveRecord::Migration
  def change
    add_column :billing_cards, :user_agent, :string
  end
end

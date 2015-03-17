class RenameMaxmindVerifiedToFraudVerified < ActiveRecord::Migration
  def change
    rename_column :billing_cards, :maxmind_verified, :fraud_verified
  end
end

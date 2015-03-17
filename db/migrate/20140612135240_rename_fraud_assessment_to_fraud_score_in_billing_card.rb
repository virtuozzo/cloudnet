class RenameFraudAssessmentToFraudScoreInBillingCard < ActiveRecord::Migration
  def change
    remove_column :billing_cards, :fraud_assessment, :string
    add_column :billing_cards, :fraud_score, :decimal
  end
end

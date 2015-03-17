class CreateBillingCards < ActiveRecord::Migration
  def change
    create_table :billing_cards do |t|
      t.string :bin
      t.string :ip_address
      t.string :city
      t.string :region
      t.string :postal
      t.string :country
      t.string :fraud_assessment
      t.string :fraud_body
      t.string :processor_token
      t.references :account

      t.timestamps
    end
  end
end

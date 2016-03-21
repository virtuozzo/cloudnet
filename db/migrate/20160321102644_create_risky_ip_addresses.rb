class CreateRiskyIpAddresses < ActiveRecord::Migration
  def change
    create_table :risky_ip_addresses do |t|
      t.string :ip_address
      t.references :account, index: true

      t.timestamps null: false
      t.datetime :deleted_at
    end
  end
end

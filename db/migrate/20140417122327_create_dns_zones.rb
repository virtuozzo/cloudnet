class CreateDnsZones < ActiveRecord::Migration
  def change
    create_table :dns_zones do |t|
      t.string :domain
      t.integer :domain_id
      t.references :user
      t.datetime :deleted_at

      t.timestamps
    end
  end
end

class CreateCertificatesLocations < ActiveRecord::Migration
  def change
    create_table :certificates_locations do |t|
      t.references :certificate
      t.references :location
    end
    
    add_index :certificates_locations, [:certificate_id, :location_id]
  end
end

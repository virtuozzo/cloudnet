class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates do |t|
      t.string :name
      t.text   :description
      t.string :certificate_avatar

      t.timestamps null: false
    end
  end
end

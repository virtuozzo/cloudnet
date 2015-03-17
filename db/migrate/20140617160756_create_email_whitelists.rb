class CreateEmailWhitelists < ActiveRecord::Migration
  def change
    create_table :email_whitelists do |t|
      t.string :email

      t.timestamps
    end
  end
end

class AddOidToCertificates < ActiveRecord::Migration
  def change
    remove_column :certificates, :certificate_avatar
    add_column :certificates, :avatar, :oid
  end
end

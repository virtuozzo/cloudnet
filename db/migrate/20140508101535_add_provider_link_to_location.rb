class AddProviderLinkToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :provider_link, :string
  end
end

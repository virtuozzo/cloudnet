class AddValidationReasonToServers < ActiveRecord::Migration
  def change
    add_column :servers, :validation_reason, :integer, default: 0
  end
end

class AddUserToServers < ActiveRecord::Migration
  def change
    add_reference :servers, :user, index: true
  end
end

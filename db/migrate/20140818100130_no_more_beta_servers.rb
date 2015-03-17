class NoMoreBetaServers < ActiveRecord::Migration
  def change
    Server.update_all(in_beta: false)
  end
end

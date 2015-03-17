class AddInBetaToServers < ActiveRecord::Migration
  def change
    add_column :servers, :in_beta, :boolean, default: false

    reversible do |dir|
      dir.up { Server.update_all(in_beta: true) }
    end
  end
end

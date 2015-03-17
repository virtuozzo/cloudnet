class CreateAccountForExistingUsers < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        User.all.find_each do |user|
          puts "-- Creating account for user #{user.full_name}"
          user.send(:create_account)
        end
      end
    end
  end
end

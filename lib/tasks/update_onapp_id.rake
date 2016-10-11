# Updates Onapp ID of user if missing

task update_onapp_id: :environment do
  onapp_users = AllUsers.new.process
  users = User.where("onapp_id IS NULL")
  users.each do |user|
    begin
      p user.email
      onapp_info = onapp_users.select {|onapp_user| onapp_user["login"] == user.onapp_user }
      if user.update_attribute(:onapp_id, onapp_info[0]['id'])
        p "success!"
      end
    rescue => e
      p e
    end
  end
end

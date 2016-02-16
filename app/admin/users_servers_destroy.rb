ActiveAdmin.register User, as: "UsersServersDestroy" do
  menu label: "Servers Destroy"
  
  actions :index
  config.filters = false
 
  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end

  index :title => 'Confirmation of Server Destroy' do
    panel "Users with negative balance" do 
      "The following users will have all their servers destroyed because of negative balance on their accouts. Please confirm that action. That will be performed during the night. Until then you can cancel that process here."
    end
    selectable_column
    column :id
    column :full_name
    column :email
    column "Notifications Sent", :notif_delivered
    column "Last Notification", :last_notif_email_sent
    column "Servers #" do |user|
      user.servers.count
    end
    column "Negative Balance" do |user|
      Invoice.pretty_total user.account.remaining_balance * -1
    end
    
    column "Destroy Confirmed" do |user|
      user.server_destroy_scheduled? ? status_tag('yes') : status_tag('no')
    end
  end
  
  batch_action :unschedule_destroy, priority: 2 do |ids|
    ids.each {|id| User.find(id).unconfirm_automatic_destroy}
    redirect_to admin_users_servers_destroys_path
  end
  
  batch_action :schedule_destroy, priority: 1 do |ids|
    ids.each {|id| User.find(id).confirm_automatic_destroy}
    redirect_to admin_users_servers_destroys_path
  end
    
  batch_action :clear_notifications do |ids|
    ids.each {|id| User.find(id).clear_unpaid_notifications}
    redirect_to admin_users_servers_destroys_path
  end
  
  controller do
    def scoped_collection
      super.servers_to_be_destroyed
    end
  end
end

ActiveAdmin.register Location do
  actions :all, except: [:destroy]
  menu priority: 5
  scope :all
  scope("Active", default: true) { |scope| scope.where(hidden: false) }
  
  permit_params :latitude, :longitude, :provider, :region_id, :country, :city, :memory, :disk, :cpu,
                :hidden, :price_memory, :price_disk, :price_cpu, :price_bw, :country_code,
                :hv_group_id, :provider_link, :network_limit, :photo_ids, :price_ip_address,
                :budget_vps, :inclusive_bandwidth, :ssd_disks

  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end

  index do
    column :id
    column :country
    column :city
    column :provider
    column :hidden

    actions
  end
  
  form do |f|
    semantic_errors *object.errors.keys

    inputs 'Location Details' do
      input :region, include_blank: 'Choose Region...'
      input :country, include_blank: 'Choose Country...', priority_countries: %w(US CA MX GB FR)
      input :city
      input :provider
      input :provider_link
      input :latitude
      input :longitude
      input :network_limit, include_blank: 'Leave Blank for Unlimited (Mbit)', hint: 'Leave Blank for Unlimited (Mbit)'
      input :hv_group_id, label: 'Hypervisor Group ID for this Location'
      input :photo_ids
      input :hidden
      input :budget_vps
      input :ssd_disks
      input :inclusive_bandwidth
    end

    inputs 'Pricing (in millicents!)' do
      input :price_memory
      input :price_disk
      input :price_cpu
      input :price_bw
      input :price_ip_address
    end

    actions
  end

  member_action :sync_templates, method: :post do
    location = Location.find(params[:id])
    LocationTasks.new.perform(:update_templates, location.id)

    flash[:notice] = "Template Sync has completed for location #{location}"
    redirect_to admin_location_path(id: location.id)
  end

  member_action :notify_users, method: :get do
    @page_title = 'Notify Users in Location'
  end

  member_action :send_users_notification, method: :post do
    location = Location.find(params[:id])
    users = location.servers.map(&:user)
    users = users.uniq(&:id)

    admins = User.where(admin: true)

    subject = params['notify_users']['subject']
    email_body = AppHelper.new.markdown(params['notify_users']['message'], false)

    (admins + users).each do |user|
      NotifyUsersMailer.delay.notify_location_email(user.id, subject, email_body, location.id)
    end

    flash[:notice] = "Notification has been emailed to #{users.length} user(s) using this location" \
      " and all jager admins."
    redirect_to admin_location_path(id: params['id'])
  end

  action_item :view, only: :show do
    link_to 'Edit Indices', admin_location_indices_path(location)
  end
  
  action_item :edit, only: :show do
    link_to 'Sync Templates', sync_templates_admin_location_path(location), method: :post
  end

  action_item :edit, only: :show do
    link_to 'Notify Users in Location', notify_users_admin_location_path(location)
  end
  
  controller do
    def find_resource
      Location.find_by_id(params[:id])
    end
  end
end

class AppHelper
  include ApplicationHelper
end
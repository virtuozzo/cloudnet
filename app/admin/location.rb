ActiveAdmin.register Location do
  before_save :update_pingdom_name
  after_save :update_new_uptimes
  actions :all, except: [:destroy]
  menu priority: 5
  scope :all
  scope("Active", default: true) { |scope| scope.where(hidden: false) }
  
  permit_params :latitude, :longitude, :provider, :region_id, :country, :city, :memory, :disk, :cpu,
                :hidden, :price_memory, :price_disk, :price_cpu, :price_bw, :country_code,
                :hv_group_id, :provider_link, :network_limit, :photo_ids, :price_ip_address,
                :pingdom_id, :budget_vps, :inclusive_bandwidth, :ssd_disks, :summary,
                certificate_ids: []
                
  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end

  filter :servers_name, as: :string, label: 'Server Name'
  filter :region
  filter :certificates
  filter :provider
  filter :country
  filter :city
  filter :hidden
  filter :provider_link
  filter :budget_vps
  filter :ssd_disks
  filter :hv_group_version

  index do
    column :id
    column :country
    column :city
    column :provider
    column :pingdom_name
    column :hidden
    column :network_limit
    column "Certificates" do |loc|
      loc.certificates.map(&:name).join(', ')
    end
    
    actions
  end
  
  form do |f|
    semantic_errors *object.errors.keys

    inputs 'Location Details' do
      input :pingdom_id, as: :select, collection: controller.pingdom_servers, hint: controller.connection_message
      input :region, include_blank: 'Choose Region...'
      input :country, include_blank: 'Choose Country...', priority_countries: %w(US CA MX GB FR)
      input :city
      input :provider
      input :provider_link
      input :latitude
      input :longitude
      input :network_limit, include_blank: '0 for Unlimited (Mbit)', hint: 'Type 0 for Unlimited (Mbit)'
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
      input :price_bw, label: "Price bandwidth / MB"
      input :price_ip_address
    end
    
    inputs 'Additional Info' do
      input :certificates, :multiple => true, as: :check_boxes
      input :summary
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
    attr_accessor :not_connected
    
    def scoped_collection
      super.includes(:certificates)
    end
    
    def find_resource
      Location.find_by_id(params[:id])
    end
    
    def pingdom_servers
      @pingdom_servers ||= begin
        data = pingdom_servers_cached
        Rails.cache.delete(pingdom_cache_key) unless pingdom_connected?
        update_selected(data)
      end
    end

    def connection_message
      pingdom_connected? ? "" : "pingdom connection error"
    end

    private
      def update_pingdom_name(loc)
        params_pingdom_id = params["location"]["pingdom_id"]
        loc.pingdom_id = params_pingdom_id.empty? ? nil : params_pingdom_id.to_i
        loc.pingdom_name = params["location"]["pingdom_id"].split(":")[1]
        return true
      end
      
      def update_new_uptimes(loc)
        return false if loc.errors.count > 0
        return true unless loc.previous_changes["pingdom_id"]
        loc.uptimes.delete_all
        UptimeUpdateServer.perform_async(loc.pingdom_id, loc.id, 150)
      end

      def pingdom_servers_cached
        Rails.cache.fetch(pingdom_cache_key, expires_in: 30.seconds) {pingdom_servers_raw}
      end
      
      def pingdom_servers_raw
        UptimeTasks.new.perform(:pingdom_servers).sort
      end

      def update_selected(options)
        location = Location.find(params["id"]) unless action_name.in? ["new", "create"]
        if pingdom_connected?
          pingdom_options_mark_selected(location, options)
        else
          pingdom_options_with_current_values(location)
        end
      end
      
      def pingdom_options_with_current_values(location)
        if location.try(:pingdom_id)
          [[location.pingdom_name, 
            "#{location.pingdom_id}:#{location.pingdom_name}", 
            {selected: true}]
          ]
        else
          []
        end
      end
    
      def pingdom_options_mark_selected(location, options)
        options = pingdom_servers_cached if options[0][1].to_i == -1
        unless location.try(:pingdom_id).nil?
          index = options.index {|o| o[1].to_i == location.pingdom_id}
          options[index].push({selected: true}) if index
        end
        options
      end
      
      def pingdom_connected?
        pingdom_servers_cached && pingdom_servers_cached[0][1].to_i > -1
      end
      
      def pingdom_cache_key
        "pingdom_servers"
      end
  end
end

class AppHelper
  include ApplicationHelper
end

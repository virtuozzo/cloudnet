ActiveAdmin.register Server do
  actions :all, except: [:new]
  menu priority: 7

  permit_params :name, :hostname, :state, :built, :locked, :suspended, :root_password,
                :cpus, :memory, :disk_size, :bandwidth

  scope("Existing", default: true) { |scope| scope.where(:deleted_at => nil) }
  scope :with_deleted
  scope :only_deleted
  
  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end

  filter :id
  filter :identifier, label: 'Onapp identifier'
  filter :name
  filter :hostname
  filter :unscoped_location, label: "Location"
  filter :unscoped_user, label: "User"

  filter :state
  filter :built
  filter :locked
  filter :suspended
  filter :stuck
  
  filter :cpus
  filter :memory
  filter :disk_size
  filter :bandwidth
  
  filter :os
  filter :os_distro
  filter :forecasted_rev
  filter :provisioner_role

  filter :created_at
  filter :updated_at
  filter :deleted_at
  filter :delete_ip_address

  show do
    default_main_content
    if server.provisioner_job_id
      panel 'Provisioner job status' do
        attributes_table_for Server do
          row :provisioner_job_status do
            DockerProvisionerTasks.new.status(server.provisioner_job_id).body rescue 'no connection'
          end
        end
      end
    end
  end
  
  index do
    column :id
    column :name
    column :hostname
    column :state
    column :built
    column :cpus
    column :memory
    column :disk_size
    column :bandwidth
    column "User", :unscoped_user
    column "Location", :unscoped_location
    column "Forecasted Rev" do |server|
      (server.forecasted_rev / Invoice::MILLICENTS_IN_DOLLAR).round(2)
    end
    column :primary_ip_address do |server|
      (server.unscoped_server_ip_addresses.find(&:primary?) || server.unscoped_server_ip_addresses.first).address rescue nil
    end
    column :deleted_at

    actions
  end
  
  csv do
    column('User Email') { |server| server.user.email }
    column :id
    column('Location') { |server| server.location }
    @resource.content_columns.each { |c| column c.name.to_sym }
  end
    
  collection_action :zombies, method: :get do
    onapp_servers   = AllServers.new.process
    deleted_servers = Server.only_deleted

    @zombies = onapp_servers.select do |server|
      existing = deleted_servers.find_by_identifier(server['identifier'])

      if existing.present?
        server['self'] = existing
        true
      else
        false
      end
    end
  end

  member_action :ip_usage, method: :get do
    server = Server.find(params[:id])
    @page_title = "IP Usage: #{server.primary_ip_address}"
    @servers = Server.with_deleted.joins(
    "LEFT JOIN server_ip_addresses ON server_ip_addresses.server_id = servers.id").includes(
    :user).where(["server_ip_addresses.address = ?", server.primary_ip_address])
  end

  action_item :edit, only: :show do
    link_to 'IP Usage', ip_usage_admin_server_path(server)
  end

  action_item :edit, only: :index do
    link_to 'Zombies', zombies_admin_servers_path
  end
  
  controller do
    def scoped_collection
      super.with_deleted
        .includes(:unscoped_user, :unscoped_location, :unscoped_server_ip_addresses)
    end
  end
end

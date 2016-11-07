ActiveAdmin.register Server do
  actions :all, except: [:new]
  menu priority: 7

  permit_params :name, :hostname, :state, :built, :locked, :suspended, :root_password,
                :cpus, :memory, :disk_size, :bandwidth, tag_ids: []

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
  filter :tags, as: :check_boxes, collection: proc { Tag.for(Server) }
  filter :identifier, label: 'Onapp identifier'
  filter :name
  filter :hostname
  filter :location, collection: proc { 
    selected_location = params[:q].blank? ? nil : params[:q][:location_id_eq]
    grouped_options_for_select([["Active", false], ["Hidden", true]].collect { |l| [l[0], Location.with_deleted.order('provider ASC').where(hidden: l[1]).load.collect { |l| [l.provider_label, l.id] } ] }, selected_location)
  }
  filter :user_full_name, as: :string, label: 'User Name'

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
    
    panel "Tags for a server" do
      attributes_table_for server do
        row :tags do |server|
          server.tag_labels.join(', ')
        end
      end
    end
    
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
    column :tags do |server| 
      server.tag_labels.join(', ')
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
  
  form do |f|
    f.semantic_errors *f.object.errors.keys
    
    f.inputs do
      f.input :name
      f.input :tags, :multiple => true, as: :check_boxes
    end
    
    actions
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
        .includes(:unscoped_user, :unscoped_location, :unscoped_server_ip_addresses, :tags)
    end
  end
end

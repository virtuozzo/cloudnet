ActiveAdmin.register Server do
  actions :all, except: [:new]
  menu priority: 7

  permit_params :name, :hostname, :state, :built, :locked, :suspended, :root_password,
                :cpus, :memory, :disk_size, :bandwidth

  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # permit_params :list, :of, :attributes, :on, :model
  #
  # or
  #
  # permit_params do
  #  permitted = [:permitted, :attributes]
  #  permitted << :other if resource.something?
  #  permitted
  # end

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
    column :user
    column :location
    column :primary_ip_address

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
    @servers = Server.with_deleted.includes(:user).find_by(primary_ip_address: server.primary_ip_address)
  end

  action_item :edit, only: :show do
    link_to 'IP Usage', ip_usage_admin_server_path(server)
  end

  action_item :edit, only: :index do
    link_to 'Zombies', zombies_admin_servers_path
  end
end

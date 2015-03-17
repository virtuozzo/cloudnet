ActiveAdmin.register Package do
  permit_params :location, :location_id, :memory, :cpus, :disk_size, :ip_addresses

  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end
end

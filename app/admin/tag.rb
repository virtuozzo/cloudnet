ActiveAdmin.register Tag do
  #actions :all, except: [:edit]
  permit_params :label
  
  filter :id
  filter :label
  
  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end
end

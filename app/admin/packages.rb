ActiveAdmin.register Package do
  permit_params :location, :location_id, :memory, :cpus, :disk_size, :ip_addresses
  
  preserve_default_filters!
  filter :location, collection: proc { 
    selected_location = params[:q].blank? ? nil : params[:q][:location_id_eq]
    grouped_options_for_select([["Active", false], ["Hidden", true]].collect { |l| [l[0], Location.with_deleted.order('provider ASC').where(hidden: l[1]).load.collect { |l| [l.provider_label, l.id] } ] }, selected_location)
  }
  
  index do
    column :id
    column :location
    column :memory
    column :cpus
    column :disk_size
    column :ip_addresses
    column :created_at
    column :updated_at
    actions
  end
  
  form do |f|
    f.semantic_errors *f.object.errors.keys
    
    f.inputs do
      f.input :location_id, as: :select, collection: grouped_options_for_select(([["Active", false], ["Hidden", true]].collect { |l| [l[0], Location.with_deleted.order('provider ASC').where(hidden: l[1]).load.collect { |l| [l.provider_label, l.id] }] }), *f.object.location_id), include_blank: false
      f.input :memory
      f.input :cpus
      f.input :disk_size
      f.input :ip_addresses
    end
    
    f.actions
  end

  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end
end

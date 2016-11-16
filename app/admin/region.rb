ActiveAdmin.register Region do

  permit_params :name, :description, :location_id
  
  preserve_default_filters!
  filter :locations, collection: proc { 
    selected_location = params[:q].blank? ? nil : params[:q][:locations_id_eq]
    grouped_options_for_select([["Active", false], ["Hidden", true]].collect { |l| [l[0], Location.with_deleted.order('provider ASC').where(hidden: l[1]).load.collect { |l| [l.provider_label, l.id] } ] }, selected_location)
  }
  
  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end
end

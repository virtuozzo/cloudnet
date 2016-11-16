ActiveAdmin.register Template do
  config.clear_action_items!
  actions :all, except: [:new, :destroy]

  permit_params :os_type, :os_distro, :identifier, :name, :min_memory, :min_disk, :hidden, :hourly_cost
  
  preserve_default_filters!
  filter :location, collection: proc { 
    selected_location = params[:q].blank? ? nil : params[:q][:location_id_eq]
    grouped_options_for_select([["Active", false], ["Hidden", true]].collect { |l| [l[0], Location.with_deleted.order('provider ASC').where(hidden: l[1]).load.collect { |l| [l.provider_label, l.id] } ] }, selected_location) 
  }
  filter :servers_name, as: :string, label: 'Server Name'
  remove_filter :servers

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

end

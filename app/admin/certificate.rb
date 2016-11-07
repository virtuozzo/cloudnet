ActiveAdmin.register Certificate do

  permit_params :name, :avatar, :description
  
  preserve_default_filters!
  filter :locations, collection: proc { 
    selected_location = params[:q].blank? ? nil : params[:q][:locations_id_eq]
    grouped_options_for_select([["Active", false], ["Hidden", true]].collect { |l| [l[0], Location.with_deleted.order('provider ASC').where(hidden: l[1]).load.collect { |l| [l.provider_label, l.id] } ] }, selected_location)
  }

  index do
    column :id
    column :name
    column :description
    column "Avatar" do |cert|
      image_tag(cert.avatar)
    end
    
    actions
  end
  
  show do
    attributes_table do
      row :id
      row :name
      row :description
      row :created_at
      row :updated_at
      row :avatar
      row "Avatar" do |cert|
        image_tag(cert.avatar)
      end
    end
  end
  
  form do |f|
    semantic_errors *object.errors.keys

    inputs do
      input :name
      input :description
      input :avatar, as: :file, label: "Avatar (64 x 64)", :hint => image_tag(object.avatar.url)
      input :avatar_cache, :as => :hidden
    end

    actions
  end
  
  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end
end

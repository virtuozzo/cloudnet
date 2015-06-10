ActiveAdmin.register Certificate do

  permit_params :name, :avatar, :description
  

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
      input :avatar, as: :file, :hint => image_tag(object.avatar.url)
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

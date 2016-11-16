ActiveAdmin.register Ticket do
  actions :all, except: [:new, :edit, :destroy]
  permit_params :status
  
  preserve_default_filters!
  filter :user_full_name, as: :string, label: 'User Name'
  filter :server_name, as: :string, label: 'Server Name'
  remove_filter :activities, :ticket_replies, :user, :server

  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end

  index do
    column :id
    column :subject
    column :created_at
    column :updated_at
    column :status
    column :department
    column :user

    actions
  end
  
  controller do
    def scoped_collection
      super.includes(:user)
    end
  end
end

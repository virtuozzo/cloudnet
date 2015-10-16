ActiveAdmin.register Index do
  belongs_to :location
  permit_params :index_cpu,  :index_iops, :index_bandwidth, :location_id, :created_at
  menu false
  navigation_menu :default
  config.filters = false
  config.sort_order = 'created_at_desc'

  index do
    column :index_cpu
    column :index_iops
    column :index_bandwidth
    column :created_at

    actions
  end

  form do |f|
    semantic_errors *object.errors.keys

    inputs 'Enter new indices' do
      input :index_cpu
      input :index_iops
      input :index_bandwidth
      input(:created_at, hint: 'Only if you want to change the chart points order') unless object.new_record?
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

  controller do
    def update
      super do |success,failure|
        success.html { redirect_to admin_location_indices_path }
      end
    end
    def create
      super do |success,failure|
        success.html { redirect_to admin_location_indices_path }
      end
    end
  end
end

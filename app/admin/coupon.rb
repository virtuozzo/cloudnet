ActiveAdmin.register Coupon do
  actions :all, except: [:destroy]

  permit_params :coupon_code, :duration_months, :percentage, :active, :expiry_date

  index do
    column :id
    column :coupon_code
    column :active
    column :percentage
    column :duration_months
    column :expiry_date
    column :created_at
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

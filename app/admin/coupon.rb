ActiveAdmin.register Coupon do
  actions :all, except: [:edit, :update, :destroy]

  permit_params :coupon_code, :duration_months, :percentage, :active

  sidebar :control_panel_links do
    ul do
      li link_to('Dashboard', root_path)
      li link_to('Servers', servers_path)
      li link_to('Tickets', tickets_path)
    end
  end
end

ActiveAdmin.register Coupon do
  actions :all, except: [:destroy]

  permit_params :coupon_code, :duration_months, :percentage, :active, :expiry_date
  
  remove_filter :accounts, :invoices, :credit_notes
  
  index do
    column :id
    column :coupon_code
    column :active
    column :percentage
    column :duration_months
    column :expiry_date do |coupon|
      span coupon.expiry_date, class: controller.expiry_warning(coupon)
    end
    column :created_at
    actions
  end
  
  form do |f|
    f.semantic_errors *f.object.errors.keys

    f.inputs "Coupon Code: #{coupon.coupon_code}" do
      f.input :coupon_code if f.object.new_record?
      f.input :active
      f.input :percentage if f.object.new_record?
      f.input :duration_months if f.object.new_record?
      f.input :expiry_date, as: :datepicker
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
  
  controller do
    def expiry_warning(coupon)
      expiry = coupon.expiry_date
      return if expiry.nil?
      
      case
      when !coupon.active then ''
      when expiry <= Date.today - 7.days then ''
      when expiry <= Date.today + 7.days then 'red'
      when expiry <= Date.today + 1.month then 'orange'
      when expiry > Date.today + 1.month then 'green'
      end
    end
  end
end

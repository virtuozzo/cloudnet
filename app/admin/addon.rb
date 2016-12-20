ActiveAdmin.register Addon do
  menu label: "Add-ons"
  actions :all, except: [:destroy]
  
  permit_params :name, :description, :price, :task, :hidden, :request_support
  
  index do
    column :id
    column :name
    column :price
    column :task
    column :hidden
    column :request_support
    column :created_at
    actions
  end
  
  form do |f|
    semantic_errors
    
    inputs do
      input :name
      input :description
      input :price, label: "Price per hour (in millicents)"
      input :task
      input :hidden
      input :request_support
    end
    
    actions
  end

end

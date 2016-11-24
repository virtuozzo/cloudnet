require 'sidekiq/web'

CloudNet::Application.routes.draw do

  constraints subdomain: /^api/ do
    mount GrapeSwaggerRails::Engine => '/docs'
    mount API => '/'
  end

  mount PostgresqlLoStreamer::Engine => "/certificate_avatar"
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  mount JasmineFixtureServer => '/spec/javascripts/fixtures' if defined?(Jasmine::Jquery::Rails::Engine)

  get 'sockets/event' => 'events#event'
  get 'search' => 'server_search#index'
  get 'features' => 'public#features', as: 'public_features'
  get 'about_us' => 'public#about_us', as: 'public_about_us'
  get 'contact' => 'public#contact', as: 'public_contact'
  post 'contact' => 'public#user_message'

  get 'public/howitworks'
  get 'payg/add_funds'
  devise_for :users, controllers: { registrations: 'registrations', sessions: 'sessions', tokens: 'tokens', confirmations: 'confirmations' }
  devise_scope :user do
    post 'users/enable_otp', to: 'tokens#enable_otp', as: 'user_tokens_enable_otp'
    post 'users/disable_otp', to: 'tokens#disable_otp', as: 'user_tokens_disable_otp'
    get 'users/otp/recovery_codes', to: 'tokens#recovery_codes', as: 'user_otp_recovery_codes'
    post 'users/otp/reset_tokens', to: 'tokens#reset_tokens', as: 'user_otp_reset_tokens'
    get 'user', to: redirect('users/edit'), as: 'user'
  end
  authenticated do
    root :to => 'dashboard#index', as: :authenticated_root
  end
  unauthenticated do
    root 'public#main'
  end

  get 'servers/create', to: 'server_wizards#new'
  resources :server_wizards, only: [:new, :create], path: 'servers/create'
  get 'servers/create/payment_step', to: 'server_wizards#payment_step'
  get 'servers/create/location_packages', to: 'server_wizards#location_packages'
  get 'servers/create/prepaid_server_cost', to: 'server_wizards#prepaid_server_cost'
  get 'servers/create/payg_server_cost', to: 'server_wizards#payg_server_cost'
  get 'servers/(:id)/create/payg', to: 'server_wizards#payg'

  resources :locations, only: [:show] do
    member do
      get :templates
      get :packages
      get :provisioner_templates
    end
  end

  resources :dashboard, only: [:index] do
    collection do
      get :stats
    end
  end

  resources :servers, only: [:index, :edit, :show, :destroy] do
    member do
      post :edit
      post :reboot
      post :shut_down
      post :start_up
      get :events
      get :console
      get :calculate_credit
      post :rebuild_network
      post :reset_root_password
      get :install_notes
    end

    resources :backups, only: [:index, :create, :destroy] do
      member do
        post :restore
      end
    end

    resources :ip_addresses
  end

  resources :billing, only: [:index] do
    collection do
      post :validate_card
      post :remove_card
      post :add_card_token
      post :update_billing
      post :make_primary
      post :toggle_auto_topup
      post :set_coupon_code
      get :payg
    end
  end

  get 'billing/invoices/:invoice_id.pdf', to: 'billing#invoice_pdf', as: 'billing_invoice_pdf'
  get 'billing/credit_notes/:credit_note_id.pdf', to: 'billing#credit_note_pdf', as: 'billing_credit_note_pdf'
  get 'billing/payment_receipts/:payment_receipt_id.pdf', to: 'billing#payment_receipt_pdf', as: 'billing_payment_receipt_pdf'

  get 'payg/confirm_card_payment', to: 'payg#confirm_card_payment'
  post 'payg/card_payment', to: 'payg#card_payment'
  get 'payg/paypal_request', to: 'payg#paypal_request'
  get 'payg/paypal_success', to: 'payg#paypal_success'
  get 'payg/paypal_failure', to: 'payg#paypal_failure'
  get 'payg/show_add_funds', to: 'payg#show_add_funds'

  resources :tickets, only: [:index, :show, :new, :create] do
    resources :ticket_replies, only: [:create]

    member do
      post :close
      post :reopen
    end

    collection do
      post :ticket_response
      post :ticket_created
    end
  end

  resources :dns_zones, only: [:index, :show, :new, :create, :destroy] do
    member do
      post :create_record
      post :edit_record
      delete :destroy_record
    end
  end

  post 'login_as', to: 'login_as#new'
  delete 'login_as', to: 'login_as#destroy'

  resources :keys

  resources :api_keys do
    member do
      post :toggle_active
    end
  end

  namespace :inapi, defaults: {format: :json} do
    namespace :v1 do
      resources :server_search, only: [:index, :create]
      get '/status', to: 'base#status'
      get '/environment', to: 'base#environment'
    end
  end

  resources :phone_numbers, only: [:create] do
    collection do
      post :verify
      post :resend
      post :reset
    end
  end

  post 'build_checker', to: 'build_checker#start'
  delete 'build_checker', to: 'build_checker#stop'

  # Add Sidekiq only if we are an admin and have authenticated as such
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
    mount PgHero::Engine, at: 'pghero'
    ActiveAdmin.routes(self)
  end

end

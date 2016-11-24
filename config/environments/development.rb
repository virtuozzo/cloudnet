CloudNet::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  #eager load negative balance protection
  Dir[Rails.root.join('app/services/negative_balance_protection/**/*.rb')].each { |file| load file }
  Dir[Rails.root.join('lib/build_checker/**/*.rb')].each { |file| load file }
  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  #config.cache_store = :null_store

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # # Compress JavaScripts and CSS.
  # config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass
  #
  # # Do not fallback to assets pipeline if a precompiled asset is missed.
  # config.assets.compile = false
  #
  # # Generate digests for assets URLs.
  # config.assets.digest = true

  config.assets.precompile += %w(
    dashboard/stats.js
    servers/*
    billing/*
    payg/*
    shared/session.js
  )

  # Mailer Default URL for Devise
  config.action_mailer.default_url_options = { host: 'localhost:3000' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_DOMAIN'],
    port: ENV['SMTP_PORT'],
    enable_starttls_auto: true,
    user_name: ENV['SMTP_USER'],
    password: ENV['SMTP_PASSWORD'],
    authentication: ENV['SMTP_AUTH_METHOD'],
    domain: 'cloud.net'
  }

  config.action_mailer.smtp_settings.merge!({ openssl_verify_mode: ENV['SMTP_SSL_VERIFY'] }) unless ENV['SMTP_SSL_VERIFY'].blank?

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.after_initialize do
    ActiveRecord::Base.logger = nil
  end
end

require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CloudNet
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'London'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Precompile additional assets.
    # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
    # Ensure images and flash are precompiled from the vendor/assets/images directory.
    # Note that assets included via `javascript_include_tag` must be explicitly asserted here to
    # have them compiled.
    config.assets.precompile += %w(
      *.png *.jpg *.jpeg *.gif *.swf *.eot *.svg *.ttf *.woff *.ico
      dashboard/stats.js
      servers/*
      billing/*
      payg/*
      shared/*
      tickets/*
      server_wizards/locations.js
      server_wizards/resources.js
      server_wizards/confirmation.js
      server_wizards/payg_confirmation.js
      intlTelInput/utils.js
    )

    config.i18n.enforce_available_locales = true
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir["#{config.root}/app/api/**/"]
#    require 'dev_database_switch'
#    include DevDatabaseSwitch
    config.generators do |g|
      g.test_framework :rspec
    end

    config.middleware.insert_before 0, 'Rack::Attack'

    config.after_initialize do
      require 'devise_otp_redirect_patch'
    end
  end
end

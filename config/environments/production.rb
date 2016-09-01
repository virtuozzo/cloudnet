CloudNet::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_files = ENV['SERVE_STATIC_FILES'] || false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  MEMCACHE_CONFIG = YAML.load(ERB.new(File.read(Rails.root.join('config', 'memcache.yml'))).result)[Rails.env].symbolize_keys
  config.cache_store =
    :dalli_store,
    MEMCACHE_CONFIG[:servers],
    { logger: Rails.logger, namespace: MEMCACHE_CONFIG[:namespace] }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # config.assets.precompile += %w( search.js )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Mailer options for Devise
  config.action_mailer.default_url_options = { host: ENV['HOST_DOMAIN'], :protocol => 'https' }
  config.action_mailer.delivery_method     = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default charset: 'utf-8'
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_DOMAIN'],
    port: ENV['SMTP_PORT'],
    enable_starttls_auto: true,
    user_name: ENV['SMTP_USER'],
    password: ENV['SMTP_PASSWORD'],
    authentication: ENV['SMTP_AUTH_METHOD'],
    domain: ENV['HOST_DOMAIN']
  }
  
  config.action_mailer.smtp_settings.merge!({ openssl_verify_mode: ENV['SMTP_SSL_VERIFY'] }) unless ENV['SMTP_SSL_VERIFY'].blank?

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Disregard our Proxy IP's
  config.action_dispatch.trusted_proxies = /^(85\.118\.238\.1[3|4][0-9]|127\.0\.0\.1|::1)$/
end

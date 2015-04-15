require 'raven'
require 'raven/integrations/sidekiq'

class SentryLogging < ErrorLogging::Methods
  CAPTURABLE_ENVS = %w(production staging)
  def initialize
    Raven.configure do |config|
      config.environments = CAPTURABLE_ENVS
      config.dsn = LOGGING[:sentry][:dsn] if Rails.env.in? CAPTURABLE_ENVS
      config.silence_ready = true
    end
  end

  def track_exception(e, params)
    Rails.logger.warn "Exception Message: #{e.message}"
    Rails.logger.warn "Backtrace:\n\t#{e.backtrace.join("\n\t")}"

    raise e unless Rails.env.in? CAPTURABLE_ENVS

    Raven.capture_exception(e, params)
  end
end

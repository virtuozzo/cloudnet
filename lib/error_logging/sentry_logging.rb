require 'raven'
require 'raven/integrations/sidekiq'

class SentryLogging < ErrorLogging::Methods
  def initialize
    Raven.configure do |config|
      config.environments = %w(production staging)
      config.dsn = LOGGING[:sentry][:dsn]
    end
  end

  def track_exception(e, params)
    Rails.logger.warn "Exception Message: #{e.message}"
    Rails.logger.warn "Backtrace:\n\t#{e.backtrace.join("\n\t")}"

    Raven.capture_exception(e, params)
  end
end

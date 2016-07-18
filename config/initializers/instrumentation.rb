# config/initializers/instrumentation.rb

# Subscribe to grape request and log with Rails.logger
ActiveSupport::Notifications.subscribe('grape_key') do |name, starts, ends, notification_id, payload|
  Rails.logger.info payload
end

ActiveSupport::Notifications.subscribe('rack.attack') do |name, starts, ends, notification_id, payload|
  data = {status: 'throttled',
          method: payload.env["REQUEST_METHOD"],
          path: payload.env["REQUEST_PATH"],
          matched: payload.env["rack.attack.matched"],
          discriminator: payload.env["rack.attack.match_discriminator"],
          match_data: payload.env["rack.attack.match_data"]}
  Rails.logger.info data
end
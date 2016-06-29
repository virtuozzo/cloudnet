# config/initializers/instrumentation.rb

# Subscribe to grape request and log with Rails.logger
ActiveSupport::Notifications.subscribe('grape_key') do |name, starts, ends, notification_id, payload|
  Rails.logger.info payload
end
redis_config = {
  url: ENV['REDIS_URI'] || 'redis://localhost:6379',
  namespace: 'cloudnet'
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

redis_config = {
  url: "redis://#{ENV['CLOUDNET_REDIS_PORT_6379_TCP_ADDR']}:6379",
  namespace: 'cloudnet'
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

redis_config = {
  url: "redis://#{ENV['CLOUDNET_REDIS_PORT_6379_TCP_ADDR']}:#{ENV['CLOUDNET_REDIS_PORT_6379_TCP_PORT']}",
  namespace: 'cloudnet'
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

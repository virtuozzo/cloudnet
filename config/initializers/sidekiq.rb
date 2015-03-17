redis_config = { url: "redis://#{ YAML.load_file(Rails.root.join('config/redis.yml'))[Rails.env.to_s] }", namespace: 'cloudnet'  }

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

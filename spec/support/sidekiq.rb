require 'sidekiq/testing'

Sidekiq::Testing.fake!
Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.remove SidekiqUniqueJobs::Client::Middleware
  end
end
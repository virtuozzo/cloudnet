AgileCRMWrapper.configure do |config|
  config.api_key = ENV['AGILECRM_API_KEY']
  config.domain = ENV['AGILECRM_DOMAIN']
  config.email = ENV['AGILECRM_EMAIL']
end
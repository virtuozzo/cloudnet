module BasicAuthHelpers
  def http_basic_auth(user, pass)
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, pass)
  end
end

RSpec.configure do |config|
  config.include BasicAuthHelpers, type: :controller
end

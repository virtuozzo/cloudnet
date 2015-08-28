# Generic API wrapper around the OnApp API
class OnappBlanketAPI
  API_URI = ENV['ONAPP_CP']
  API_USER = ENV['ONAPP_USER']
  API_PASS = ENV['ONAPP_PASS']

  # General purpose connection to the Onapp API using the Blanket gem.
  # See: https://github.com/inf0rmer/blanket
  # Eg;
  # `github = Blanket.wrap("https://api.github.com")`
  # Get some user's info...
  # `user = github.users('inf0rmer').get`
  def connection(user)
    check_for_env_credentials
    disable_ssl_verification_in_non_production
    Blanket.wrap(
      API_URI,
      extension: :json, # Always appends '.json' to the end of the request URL
      headers: {
        'Authorization' => "Basic #{auth_sig(user)}"
      }
    )
  end

  # Create the base64 encoded string for the Basic Auth header
  def auth_sig(user)
    if user.is_a? User
      username = user.onapp_user
      password = user.onapp_password
    elsif user.is_a? Array
      username = user[0]
      password = user[1]
    elsif user == :admin
      username = API_USER
      password = API_PASS
    end
    Base64.encode64("#{username}:#{password}").delete("\r\n")
  end

  # Just a means to make it clear that you're getting and *admin* connection
  def admin_connection
    connection(:admin)
  end

  def check_for_env_credentials
    return if API_URI && API_USER && API_PASS
    fail 'Cannot find OnApp API credentials in ENV[]'
  end

  def disable_ssl_verification_in_non_production
    HTTParty::Basement.default_options.update(verify: false)
  end
end

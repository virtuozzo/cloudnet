class ServerConsole
  def initialize(server, user)
    @server = server
    @user = user
  end
  
  def resolve_redirects(url)
    response = fetch_response(url, method: :head)
    if response
      return response.to_hash[:url].to_s
    else
      return nil
    end
  end

  def fetch_response(url, method: :get)
    conn = Faraday.new do |b|
      b.use FaradayMiddleware::FollowRedirects;
      b.adapter :net_http
      b.basic_auth @user.onapp_user, @user.onapp_password
    end
    return conn.send method, url
  rescue Faraday::Error, Faraday::Error::ConnectionFailed => e
    return nil
  end

  def process
    console_url = resolve_redirects("#{ONAPP_CP[:uri]}/virtual_machines/#{@server.identifier}/console_popup")
    { console_src: console_url }
  end
end

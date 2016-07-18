class Rack::Attack
  
  unless Rails.env.test?
    # Throttle brute-force login POST
    throttle('sign_in/ip', :limit => 2, :period => 10.seconds) do |req|
      req.post? && req.path == '/users/sign_in' && req.ip
    end

    throttle('sign_in/ip2', :limit => 10, :period => 300.seconds) do |req|
      if req.post? && req.path == '/users/sign_in'
        req.ip
      end
    end

    # Throttle API POST by IP
    throttle('api/post/ip', :limit => 2, :period => 10.seconds) do |req|
      req.post? && req.host =~ /^api/ && req.ip
    end
  
    throttle('api/post2/ip', :limit => 10, :period => 120.seconds) do |req|
      req.post? && req.host =~ /^api/ && req.ip
    end
  
    # Throttle API GET by IP
    throttle('api/get/ip', :limit => 20, :period => 60.seconds) do |req|
      if req.get? && req.host =~ /^api/
        if req.path =~ /^\/(docs|assets|api)/
          false
        else
          req.ip
        end
      end
    end
  
    # Throttle API DELETE by IP
    throttle('api/delete/ip', :limit => 2, :period => 10.seconds) do |req|
      req.delete? && req.host =~ /^api/ && req.ip
    end
  
    throttle('api/delete2/ip', :limit => 10, :period => 120.seconds) do |req|
      req.delete? && req.host =~ /^api/ && req.ip
    end
  
    # Throttle API PUT/PATCH by IP
    throttle('api/put/ip', :limit => 2, :period => 10.seconds) do |req|
      (req.put? || req.patch?) && req.host =~ /^api/ && req.ip
    end
  
    throttle('api/put2/ip', :limit => 10, :period => 120.seconds) do |req|
      (req.put? || req.patch?) && req.host =~ /^api/ && req.ip
    end
  end
  
  # Response 503 because it may make attacker think that 
  # they have successfully DOSed the site.
  self.throttled_response = lambda do |env|
    body = {"error" => "Too many requests"}.to_json
    [ 503, {'Content-Type' => 'application/json'}, [body]]
  end
end
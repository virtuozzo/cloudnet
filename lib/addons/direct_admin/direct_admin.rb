module DirectAdmin
  class License
    BASE_URI = "https://www.directadmin.com"
    DA_USER_ID = KEYS[:direct_admin][:user_id]
    DA_PASSWORD = KEYS[:direct_admin][:password]
    DA_PRODUCT_ID = KEYS[:direct_admin][:product_id]
    
    attr_reader :api, :server_addon, :server
    
    def initialize(server_addon)
      @server_addon = server_addon
      @server = server_addon.server
      @api ||= Faraday.new(:url => "#{BASE_URI}") do |conn|
        # conn.use Faraday::Response::Logger, Rails.logger
        conn.adapter Faraday.default_adapter
        conn.basic_auth DA_USER_ID, DA_PASSWORD
      end
    end
    
    def process
      if server_addon.deleted?
        delete_license if server_addon.addon_info && !server_addon.addon_info[:license_id].blank?
      else
        create_license
        activate_license
      end
    end
    
    def create_license
      api.headers['Referer'] = 'https://www.directadmin.com/clients/createlicense.php'
      license = api.post '/cgi-bin/createlicense', create_license_params
      server_addon.update_attributes(addon_info: {license_id: license.headers["x-lid"]})
    end
    
    def activate_license
      api.headers['Referer'] = 'https://www.directadmin.com/clients/makepayment.php'
      api.post '/cgi-bin/makepayment', activate_license_params
    end
    
    def delete_license
      api.headers['Referer'] = 'https://www.directadmin.com/clients/license.php'
      api.post '/cgi-bin/deletelicense', delete_license_params
    end
    
    # Utility methods - could be used for maintenance purposes
      
    def get_licenses
      response = api.get '/clients/api/list.php'
      parse_respose(response.body, "&")
    end
    
    def get_products
      response = api.get '/clients/api/products.php'
      parse_respose(response.body)
    end
    
    def get_os_list
      response = api.get '/clients/api/os_list.php'
      parse_respose(response.body)
    end
    
    private
    
    def create_license_params
      {
        'id'            => DA_USER_ID,
        'password'      => DA_PASSWORD,
        'pid'           => DA_PRODUCT_ID,               # product ID
        'ip'            => server.primary_ip_address,   # server primary ip address
        'name'          => server.name,                 # server name
        'email'         => server.user.email,           # users email address
        'os'            => formatted_os,                # server operating system
        'domain'        => formatted_hostname,          # server host name
        'api'           => '1',
        'pass1'         => 'rootpass',
        'pass2'         => 'rootpass',
        'username'      => 'admin',
        'admin_pass1'   => 'ignored',
        'admin_pass2'   => 'ignored',
        'ns1'           => 'ns1.ignored.com',
        'ns2'           => 'ns2.ignored.com',
        'ns_on_server'  => 'yes',
        'ns1ip'         => '0.0.0.0',
        'ns2ip'         => '0.0.0.0',
        'payment'       => 'balance'
      }.to_query
    end
    
    def activate_license_params
      {
        'uid'           => DA_USER_ID,
        'password'      => DA_PASSWORD,
        'action'        => 'pay',
        'lid'           => server_addon.addon_info[:license_id],
        'api'           => 1
      }.to_query
    end
    
    def delete_license_params
      {
        'uid'           => DA_USER_ID,
        'lid'           => server_addon.addon_info[:license_id],
        'password'      => DA_PASSWORD
      }.to_query
    end
    
    # should match with DirectAdmin's format of OS name
    def formatted_os
      'ES 7.0 64'
      # server.template.name
      # TODO: Should match server's template with list from get_os_list()
    end
    
    # makes sure the hostname is as per DirectAdmin's specification
    def formatted_hostname
      (server.hostname.split('.').size < 2) ? (server.hostname + ".host") : server.hostname
    end
    
    # parse the plain text response from API, this could easily break!
    def parse_respose(body, delimiter = "\n")
      body_ar = body.split(delimiter)
      results = body_ar.map {|r| [r.split('=')[0], r.split('=')[1]]}
      results_ha = Hash[results]
    end
    
  end
end

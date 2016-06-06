module SiftScience
  
  class Device
    BASE_URI = "https://api3.siftscience.com/v3/accounts"
    ACCOUNT_ID = KEYS[:sift_science][:account_id]
    API_KEY = KEYS[:sift_science][:api_key]
    
    attr_reader :api
    
    def initialize
      @api ||= Faraday.new(:url => "#{BASE_URI}/#{ACCOUNT_ID}/") do |conn|
        conn.request  :json
        conn.response :json
        # conn.use Faraday::Response::Logger, Rails.logger
        conn.adapter Faraday.default_adapter
        conn.basic_auth API_KEY, nil
      end
    end
    
    def session(session_id)
      api.get "sessions/#{session_id}"
    end
    
    def device(device_id)
      api.get "devices/#{device_id}"
    end
    
    def label(device_id, label)
      api.put "devices/#{device_id}/label", label_data(label)
    end
    
    def devices(user_id)
      api.get "users/#{user_id}/devices"
    end
    
    private
    
    def label_data(label)
      { "label" => label }
    end
  end

end

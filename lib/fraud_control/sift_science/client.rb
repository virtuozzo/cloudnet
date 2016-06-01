require 'sift'

Sift.api_key = KEYS[:sift_science][:api_key]

module SiftScience
  
  class Client
    attr_reader :client
    
    API_INTERVAL = 30
    
    # Error codes as per https://siftscience.com/developers/docs/curl/events-api/error-codes
    RETRY_ERROR_CODES = [-4, -3, -2, -1]
    LOG_ERROR_CODES = [51, 52, 53, 55, 56, 57, 60, 104, 105]
    
    def initialize
      @client ||= Sift::Client.new
    end
    
    def create_event(event_type, properties, return_action = false)
      client.track(event_type, properties, 2, nil, false, KEYS[:sift_science][:api_key], return_action)
    end
    
    def create_label(user_id, properties)
      client.label(user_id, properties)
    end
    
    def remove_label(user_id)
      client.unlabel(user_id)
    end
    
    def score(user_id)
      client.score(user_id)
    end
  end

end

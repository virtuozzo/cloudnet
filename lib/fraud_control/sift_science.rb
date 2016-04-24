require 'sift'

Sift.api_key = KEYS[:sift_science][:api_key]

class SiftScience
  
  def initialize
    @client = Sift::Client.new
  end
  
  def create_event(event_type, properties)
    @client.track(event_type, properties)
  end
  
end

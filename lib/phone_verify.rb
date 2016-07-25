require 'nexmo'

class PhoneVerify
  
  attr_reader :client
  
  def initialize
    @client = Nexmo::Client.new
  end
  
  def start(number)
    response = client.start_verification(number: number, brand: ENV['BRAND_NAME'])
    if response['status'] == '0'
      return [true, response['request_id']]
    else
      return [false, response['error_text']]
    end
  end
  
  def check(verification_id, pin)
    response = client.check_verification(verification_id, code: pin)
    if response['status'] == '0'
      return [true, response['event_id']]
    else
      return [false, response['error_text']]
    end
  end
  
  def cancel(verification_id)
    response = client.cancel_verification verification_id
    response['status'] == '0'
  end
  
  def trigger_next(verification_id)
    response = client.trigger_next_verification_event verification_id
    response['status'] == '0'
  end
  
  def search(verification_id)
    client.get_verification verification_id
  end
  
end

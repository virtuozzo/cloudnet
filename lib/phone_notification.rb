require 'plivo'
include Plivo

AUTH_ID = ENV['PLIVO_AUTH_ID']
AUTH_TOKEN = ENV['PLIVO_AUTH_TOKEN']

class PhoneNotification
  
  def self.send_text(number, text)
    p = RestAPI.new(AUTH_ID, AUTH_TOKEN)
    params = {
        'src'     => ENV['PLIVO_PHONE_NUMBER'],
        'dst'     => number,
        'text'    => text,
        'method'  => 'POST'
        # 'url'     => 'http://example.com/report/', # The URL to which with the status of the message is sent
    }
    p.send_message(params)
  end
  
end

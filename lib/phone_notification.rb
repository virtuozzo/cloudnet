require 'plivo'
include Plivo

AUTH_ID = KEYS[:plivo][:auth_id]
AUTH_TOKEN = KEYS[:plivo][:auth_token]

class PhoneNotification
  
  def self.send_text(number, text)
    p = RestAPI.new(AUTH_ID, AUTH_TOKEN)
    params = {
        'src'     => KEYS[:plivo][:phone_number],
        'dst'     => number,
        'text'    => text,
        'method'  => 'POST'
        # 'url'     => 'http://example.com/report/', # The URL to which with the status of the message is sent
    }
    p.send_message(params)
  end
  
end

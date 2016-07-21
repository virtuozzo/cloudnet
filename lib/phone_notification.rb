require 'nexmo'

class PhoneNotification
  
  def self.send_text(number, text)
    client = Nexmo::Client.new
    response = client.send_message(from: ENV['BRAND_NAME'], to: number, text: text)
    response['messages'].first
  end
  
end

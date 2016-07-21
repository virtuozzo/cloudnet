class SendPhoneVerificationPin
  include Sidekiq::Worker

  def perform(user_id)
    return false unless KEYS[:nexmo][:api_key].present?
    user = User.find user_id
    number = user.unverified_phone_number_full
    return false if number.blank?
    text = user.phone_verification_sms
    begin
      response = PhoneNotification.send_text number, text
      if response['status'] == '0'
        return true
      else
        raise "Error: #{response['error-text']}"
      end
    rescue StandardError => e
      ErrorLogging.new.track_exception(e,
        extra: {
          source: 'SendTextNotification',
          number: number,
          text: text,
          api_status: response['status'],
          error_text: response['error-text'],
          message_id: response['message-id']
        }
      )
      return response['error-text']
    end
  end
end

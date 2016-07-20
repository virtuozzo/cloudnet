class SendPhoneVerificationPin
  include Sidekiq::Worker

  def perform(user_id)
    return false unless KEYS[:plivo][:auth_id].present?
    user = User.find user_id
    number = user.unverified_phone_number_full
    return false if number.blank?
    text = user.phone_verification_sms
    begin
      response = PhoneNotification.send_text number, text
      # response_code = response.first
      # if response_code != 202
        # Retry ?
      # end
    rescue StandardError => e
      ErrorLogging.new.track_exception(e,
        extra: {
          source: 'SendTextNotification',
          number: number,
          text: text,
          api_response: response.last["message"],
          api_id: response.last["api_id"],
          message_uuid: response.last["message_uuid"]
        }
      )
    end
  end
end

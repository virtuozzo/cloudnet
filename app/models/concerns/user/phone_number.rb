require 'active_support/concern'

class User < ActiveRecord::Base
  module User::PhoneNumber
    extend ActiveSupport::Concern
    
    def phone_verification_sms
      "Your #{ENV['BRAND_NAME']} phone verification PIN is #{phone_verification_pin}. This PIN will expire in one hour."
    end
    
    def phone_verification_pin
      Rails.cache.fetch(["phone_verification_pin", id], expires_in: 1.hour) do
        generate_phone_verification_pin
      end
    end
    
    def generate_phone_verification_pin
      rand(0000..9999).to_s.rjust(4, "0")
    end
    
    def phone_number_parsed
      Phonelib.parse(phone_number)
    end
    
    def phone_number_full
      phone_number_parsed.full_e164
    end
    
    def phone_verified?
      !phone_verified_at.nil?
    end
  end
end

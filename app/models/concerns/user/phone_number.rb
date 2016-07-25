require 'active_support/concern'

class User < ActiveRecord::Base
  module User::PhoneNumber
    extend ActiveSupport::Concern
    
    def phone_verification_id
      Rails.cache.read(["phone_verification_id", id])
    end
    
    def phone_verification_id=(verification_id)
      Rails.cache.write(["phone_verification_id", id], verification_id, expires_in: 1.hour)
    end
    
    def phone_number_full
      Phonelib.parse(phone_number).full_e164
    end
    
    def unverified_phone_number
      Rails.cache.read(["unverified_phone_number", id])
    end
    
    def unverified_phone_number=(number)
      Rails.cache.write(["unverified_phone_number", id], number, expires_in: 1.hour)
    end
    
    def unverified_phone_number_full
      Phonelib.parse(unverified_phone_number).full_e164
    end
    
    def phone_verified?
      phone_number.present? && !phone_verified_at.nil?
    end
  end
end

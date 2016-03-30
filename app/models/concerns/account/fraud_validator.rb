require 'active_support/concern'

class Account < ActiveRecord::Base
  module Account::FraudValidator
    extend ActiveSupport::Concern
    
    VALID_FRAUD_SCORE = 40
    VALIDATION_REASONS = ["None", "Minfraud", "IP history", "Risky card attempts"]
    
    def fraud_safe?(ip = nil)
      fraud_validation_reason(ip) == 0
    end
    
    def fraud_validation_reason(ip = nil)
      return case
        when !minfraud_safe? ; 1
        when !safe_ip?(ip) ; 2
        when !permissible_card_attempts? ; 3
        else ; 0
        end
    end

    # Checks against minfraud data we have on db
    def minfraud_safe?
      return true if primary_billing_card.blank? || primary_billing_card.fraud_safe?
      # fraud_body = JSON.parse primary_billing_card.fraud_body
      (primary_billing_card.fraud_verified? && 
        primary_billing_card.fraud_score <= VALID_FRAUD_SCORE
        # !fraud_body["anonymous_proxy"] &&
        # fraud_body["country_match"] &&
        # fraud_body["proxy_score"] < 2.0
        ) rescue false
    end
    
    # Check list of IPs that has a history for fraud
    def safe_ip?(ip = nil)
      ips = []
      ips << ip unless ip.blank?
      ips << primary_billing_card.ip_address unless primary_billing_card.blank?
      RiskyIpAddress.where("ip_address IN (?)", ips).count == 0
    end
    
    # Number of bad / risky card attempts
    def permissible_card_attempts?
      risky_card_attempts <= 3
    end
  end
end

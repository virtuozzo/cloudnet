require 'active_support/concern'

class Account < ActiveRecord::Base
  module Account::FraudValidator
    extend ActiveSupport::Concern
    
    VALID_FRAUD_SCORE = 40
    VALIDATION_REASONS = ["None", "Minfraud", "IP history", "Risky card attempts", "Chargeback"]
    
    def fraud_safe?(ip = nil)
      fraud_validation_reason(ip) == 0
    end
    
    def fraud_validation_reason(ip = nil)
      return case
        when !minfraud_safe? ; 1
        when !safe_ip?(ip) ; 2
        when !permissible_card_attempts? ; 3
        when received_chargeback? ; 4
        else ; 0
        end
    end

    # Checks against minfraud data we have on db
    def minfraud_safe?
      return true if billing_cards.blank?
      return true if maxmind_exempt?
      return true if billing_cards.select {|card| !card.fraud_safe?}.blank?
      billing_cards.each do |card|
        next if card.fraud_safe?
        is_valid_card = (card.fraud_verified? && card.fraud_score <= VALID_FRAUD_SCORE) rescue false
        return false unless is_valid_card
      end
      return true
    end
    
    # Check list of IPs that has a history for fraud
    def safe_ip?(ip = nil)
      ips = []
      ips << ip unless ip.blank?
      billing_cards.map(&:ip_address).each {|i| ips << i} unless billing_cards.blank?
      ips.push user.current_sign_in_ip, user.last_sign_in_ip
      RiskyIpAddress.where("ip_address IN (?)", ips.flatten.uniq).count == 0
    end
    
    # Number of bad / risky card attempts
    def permissible_card_attempts?
      risky_card_attempts <= 3
    end
    
    def received_chargeback?
      false
    end
  end
end

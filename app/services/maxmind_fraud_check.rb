require 'maxmind'
require 'digest/md5'

Maxmind.license_key = KEYS[:maxmind][:license_key]
Maxmind::Request.default_request_type = 'standard'

class MaxmindFraudCheck
  def initialize(user, card)
    @user = user
    @card = card
  end

  def process
    if @user.account.maxmind_exempt?
      return true
    end

    begin
      account   = @user.account
      email_md5 = Digest::MD5.hexdigest(@user.email.downcase)

      request = Maxmind::Request.new(
        client_ip:    @card.ip_address,
        city:         @card.city.downcase,
        region:       @card.region.downcase,
        postal:       @card.postal.downcase,
        country:      @card.country.downcase,
        email:        @user.email.downcase,
        bin:          @card.bin,
        user_agent:   @card.user_agent
      )

      response = request.process!
      attributes = response.attributes

      @card.fraud_score = attributes[:risk_score]
      @card.fraud_body  = attributes.to_json
      @card.fraud_verified = true

      # Just do a final check for the number of queries just in case it
      # is running low, we need to upgrade
      if attributes[:queries_remaining] < 15
        # Mail out an email
      end

      true
    rescue Exception => e
      @card.errors.add(:base, 'Could not complete card verification. Please try again in a few minutes or contact support')
      false
    end
  end
end

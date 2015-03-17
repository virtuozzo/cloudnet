class LoadDnsZoneRecords
  def initialize(domain, user)
    @domain = domain
    @user   = user
  end

  def process
    squall = Squall::DnsZone.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    squall.records(@domain.domain_id)
  end
end

class CreateDnsRecord
  def initialize(domain, params, user)
    @domain = domain
    @params = params
    @user   = user
  end

  def process
    squall = Squall::DnsZone.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    squall.create_record(@domain.domain_id, @params)
  end
end

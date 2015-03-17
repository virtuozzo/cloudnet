class EditDnsRecord
  def initialize(domain, record, params, user)
    @domain = domain
    @record = record
    @params = params
    @user   = user
  end

  def process
    squall = Squall::DnsZone.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    squall.edit_record(@domain.domain_id, @record, @params)
  end
end

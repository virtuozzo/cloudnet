class DeleteDnsRecord
  def initialize(domain, record, user)
    @domain = domain
    @record = record
    @user   = user
end

  def process
    squall = Squall::DnsZone.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    squall.delete_record(@domain.domain_id, @record)
  end
end

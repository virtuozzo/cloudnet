class DeleteDnsZone
  def initialize(record, user)
    @record = record
    @user   = user
  end

  def process
    squall = Squall::DnsZone.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    squall.delete(@record.domain_id)
  end
end

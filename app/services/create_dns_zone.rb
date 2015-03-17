class CreateDnsZone
  def initialize(record, user)
    @record = record
    @user   = user
  end

  def process
    squall = Squall::DnsZone.new(uri: ONAPP_CP[:uri], user: @user.onapp_user, pass: @user.onapp_password)
    params = {
      name: @record.domain,
      auto_populate: (@record.autopopulate ? 1 : 0)
    }

    squall.create(params)
  end
end

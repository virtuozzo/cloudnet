class ServerUsageHourlyTask < BaseTask
  def initialize(user, servers)
    @user     = user
    @servers  = servers
  end

  def process
    @servers.each do |server|
      account = @user.account
      ServerHourlyTransaction.generate_transaction(account, server, account.coupon).save
    end

    true
  end
end

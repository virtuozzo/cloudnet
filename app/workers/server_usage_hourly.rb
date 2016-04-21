class ServerUsageHourly
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed
  
  def perform
    Account.all.find_each do |account|
      user    = account.user
      payg    = user.servers.where(payment_type: 'payg')
      next if payg.empty?

      begin
        ServerUsageHourlyTask.new(user, payg).process
      rescue Exception => e
        ErrorLogging.new.track_exception(e, extra: { current_user: user, source: 'ServerUsageHourly' })
      end
    end
  end
end

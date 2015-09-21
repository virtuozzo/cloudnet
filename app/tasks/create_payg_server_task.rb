class CreatePaygServerTask < BaseTask
  def initialize(wizard, user)
    super
    @wizard = wizard
    @user   = user
    @server = nil
  end

  def process
    account = @user.account

    begin
      remote = CreateServer.new(@wizard, @user).process
      if remote.nil? || remote['id'].nil?
        errors.push('Could not create server on remote system. Please try again later')
        return false
      end

      @server = @wizard.save_server_details(remote, @user)
      transaction = ServerHourlyTransaction.generate_transaction(@user.account, @server, @user.account.coupon)
      transaction.save!
    rescue Faraday::Error::ClientError => e
      ErrorLogging.new.track_exception(e, extra: { current_user: @user, source: 'CreatePaygServerTask', faraday: e.response })
      errors.push('Could not create server on remote system. Please try again later')
      return false
    end

    MonitorServer.perform_in(MonitorServer::POLL_INTERVAL.seconds, @server.id, @user.id)
    true
  end

  attr_reader :server
end

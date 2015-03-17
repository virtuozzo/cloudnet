class DestroyPaygServerTask < BaseTask
  def initialize(server, user, user_ip)
    super
    @server = server
    @user   = user
    @ip     = user_ip
  end

  def process
    tasker  = ServerTasks.new
    account = @user.account

    begin
      tasker.perform(:destroy, @user.id, @server.id)
      @server.destroy_with_ip(@ip)
    rescue Faraday::Error::ClientError => e
      ErrorLogging.new.track_exception(e, extra: { current_user: @user, source: 'DestroyPaygServerTask', faraday: e.response })
      errors.push 'Could not schedule destroy of server. Please try again later'
      return false
    rescue Exception => e
      ErrorLogging.new.track_exception(e, extra: { current_user: @user, source: 'DestroyPaygServerTask' })
      errors.push 'Could not schedule destroy of server. Please try again later'
      return false
    end

    true
  end
end

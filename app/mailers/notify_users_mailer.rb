class NotifyUsersMailer < ActionMailer::Base
  default from: ENV['MAILER_NOTIFICATIONS_DEFAULT_FROM']

  def notify_email(user, subject, body)
    @user = user
    @body = body
    mail(to: @user[:email], subject: subject)
  end

  def notify_location_email(user_id, subject, body, location_id)
    @user = User.find(user_id)
    @body = body
    @location = Location.find(location_id)
    @servers = @user.servers.select { |s| s.location_id == @location.id }
    mail(to: @user.email, subject: subject)
  end
  
  def notify_stuck_state(user, server)
    @user = user
    @server = server
    recipients = [@user.email, "support@cloud.net"]
    mail(to: recipients.join(","), subject: 'Your server is still building')
  end
end

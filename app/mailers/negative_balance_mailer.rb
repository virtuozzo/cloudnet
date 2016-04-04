class NegativeBalanceMailer < ActionMailer::Base
  default from: ENV['MAILER_NOTIFICATIONS_DEFAULT_FROM']
  
  def shutdown_warning_email_to_user(user)
    Rails.logger.info "Shutdown warning email to #{user.email}"
    
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: user.email,
      subject: "#{ENV['BRAND_NAME']}: negative balance - shutdown warning"
    )
  end
  
  def shutdown_action_email_to_user(user)
    Rails.logger.info "Shutdown action email to #{user.email}"
    
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: user.email,
      subject: "#{ENV['BRAND_NAME']}: negative balance - all your servers shut down"
    )
  end
  
  def destroy_warning_email_to_user(user)
    Rails.logger.info "DESTROY! warning email to #{user.email}"
    
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: user.email,
      subject: "#{ENV['BRAND_NAME']}: negative balance - DESTROY warning!"
    )
  end
  
  def destroy_action_email_to_user(user)
    Rails.logger.info "DESTROY! action email to #{user.email}"
    
    @user = user
    @pretty_negative_balance = Invoice.pretty_total user.account.remaining_balance
    mail(
      to: user.email,
      subject: "#{ENV['BRAND_NAME']}: negative balance - servers destroyed"
    )
  end
end

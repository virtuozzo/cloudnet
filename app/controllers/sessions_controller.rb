class SessionsController < Devise::SessionsController
  include SessionOrderReport
  before_action :prepare_order
  
  def new
    analytics_info
    flash[:notice] = session.delete(:registration_flash) if session[:registration_flash]
    super
  end
  
  private
  
  def analytics_info
    Analytics.track(current_user, event: 'Login Page')
  end
end

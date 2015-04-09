class SessionsController < Devise::SessionsController
  include SessionOrderReport
  before_action :prepare_order
  
  def new
    flash[:notice] = session.delete(:registration_flash) if session[:registration_flash]
    super
  end
end

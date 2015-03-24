class SessionsController < Devise::SessionsController
  layout "public"
  
  def new
    flash[:notice] = session.delete(:registration_flash) if session[:registration_flash]
    super
  end
end

class SessionsController < Devise::SessionsController
  def new
    flash[:notice] = session.delete(:registration_flash) if session[:registration_flash]
    super
  end
end

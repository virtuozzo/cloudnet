class RegistrationsController < Devise::RegistrationsController
  include SessionOrderReport
  before_action :prepare_order
  # def new
  # end
  #
  # def create
  #   flash[:info] = 'Registrations are not open yet for the Cloud.net beta, but please check back soon'
  #   redirect_to :back
  # end

  def new
    # We want to have the ability to fill in some params
    #prepare_order if session[:user_return_to]
    analytics_info
    build_resource(sign_up_params)
    respond_with resource
  end

  protected

  def after_inactive_sign_up_path_for(resource)
    session[:registration_flash] = flash[:notice] if flash[:notice]
    super
  end
  
  def analytics_info
    Analytics.track(current_user, {event: 'Registration Page'}, anonymous_id)
  end
end

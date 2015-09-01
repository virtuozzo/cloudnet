class RegistrationsController < Devise::RegistrationsController
  include SessionOrderReport
  before_action :prepare_order

  def new
    analytics_info unless monitoring_service?
    build_resource(sign_up_params)
    respond_with resource
  end

  protected

  def after_inactive_sign_up_path_for(resource)
    session[:registration_flash] = flash[:notice] if flash[:notice]
    super
  end
  
  def analytics_info
    Analytics.track(current_user, {event: 'Registration Page'}, anonymous_id, request)
  end
end

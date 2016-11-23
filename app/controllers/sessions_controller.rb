class SessionsController < Devise::SessionsController
  include SessionOrderReport
  before_action :prepare_order

  def new
    analytics_info unless monitoring_service?
    flash[:notice] = session.delete(:registration_flash) if session[:registration_flash]
    super
  end

  def destroy
    properties = { "$user_id" => current_user.id, "$session_id" => anonymous_id }
    create_sift_event "$logout", properties
    delete_intercom_cookies
    super
  end

  private
  
  def delete_intercom_cookies
    return if KEYS[:intercom][:app_id].blank?
    cookies.delete "intercom-id-#{KEYS[:intercom][:app_id]}", domain: :all
    cookies.delete "intercom-session-#{KEYS[:intercom][:app_id]}", domain: :all
  end

  def analytics_info
    Analytics.track(current_user, event_details, anonymous_id, request)
  end

  def event_details
    {event: 'Login Page',
      properties: UtmTracker.extract_properties(params)
    }
  end
end

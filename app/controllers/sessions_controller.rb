class SessionsController < Devise::SessionsController
  include SessionOrderReport
  before_action :prepare_order

  def new
    analytics_info unless monitoring_service?
    flash[:notice] = session.delete(:registration_flash) if session[:registration_flash]
    super
  end

  def destroy
    create_sift_event
    super
  end

  private

  def create_sift_event
    properties = {
      "$user_id": current_user.id,
      "$session_id": anonymous_id
    }
    CreateSiftEvent.perform_async("$logout", properties)
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

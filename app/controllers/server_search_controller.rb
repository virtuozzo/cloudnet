class ServerSearchController < ApplicationController
  skip_before_action :authenticate_user!
  #before_action {redirect_to :root if user_signed_in?}
  layout "public"
  
  def index
    @event = current_user ? "online" : "offline"
    analytics_info unless monitoring_service?
  end
  
  def create
    redirect_to :sign_in
  end
  
  private
  def analytics_info
    Analytics.track(current_user, event_details, anonymous_id)
  end
  
  def event_details
    {event: 'Marketplace - ' + @event,
      properties: UtmTracker.extract_properties(params)
    }
  end
end

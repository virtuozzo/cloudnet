class ServerSearchController < ApplicationController
  skip_before_action :authenticate_user!
  #before_action {redirect_to :root if user_signed_in?}
  layout "public"
  
  def index
    set_event
    analytics_info unless monitoring_service?
    if current_user.try(:servers_blocked?)
      redirect_to billing_index_path, 
          notice: "You have to pay your invoice before creating a new server"
    end
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
  
  def set_event
    @event = current_user ? "online" : "offline"
    @event = "blocked - Billing" if current_user.try(:servers_blocked?)
  end
end

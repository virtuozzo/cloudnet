class PublicController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :clear_remembered_path
  
  def main
    @regions = Region.active
    @cheapest = Location.cheapest
    analytics_info unless monitoring_service?
  end
  
  def user_message
    Thread.new{EnquiryMailer.contact_page(params[:enquiry]).deliver_now}
  end
  
  private
  def clear_remembered_path
    session[:user_return_to] = nil
  end
  
  def analytics_info
    Analytics.track(current_user, event_details, anonymous_id, request)
  end
  
  def event_details
    {event: 'Main Page',
      properties: {
        environment: Rails.env,
        agent: request.user_agent
      }.merge(UtmTracker.extract_properties(params))
    }
  end
end

class ServerSearchController < ApplicationController
  skip_before_action :authenticate_user!
  #before_action {redirect_to :root if user_signed_in?}
  layout "public"
  
  def index
    analytics_info
  end
  
  def create
    redirect_to :sign_in
  end
  
  private
  def analytics_info
    event = current_user ? "online" : "offline"
    Analytics.track(current_user, {event: 'Marketplace - ' + event}, anonymous_id)
  end
end

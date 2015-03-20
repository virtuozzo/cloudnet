class PublicController < ApplicationController
  skip_before_action :authenticate_user!
  
  def user_message
    Thread.new{EnquiryMailer.contact_page(params[:enquiry]).deliver_now}
  end
  
end

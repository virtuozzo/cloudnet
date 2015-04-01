class PublicController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :clear_remembered_path
  
  def user_message
    Thread.new{EnquiryMailer.contact_page(params[:enquiry]).deliver_now}
  end
  
  private
  def clear_remembered_path
    session[:user_return_to] = nil
  end
  
end

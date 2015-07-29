class Api::V1::BaseController < Api::ApplicationController 
  def status
    render :text => "OK"
  end
  def environment
    render :json => '"' + Rails.env.to_s + '"'
  end
end

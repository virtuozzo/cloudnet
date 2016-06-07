class Inapi::V1::BaseController < Inapi::ApplicationController

  def status
    render :text => "OK"
  end

  def environment
    render :json => '"' + Rails.env.to_s + '"'
  end
  
end
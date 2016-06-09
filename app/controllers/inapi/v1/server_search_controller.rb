class Inapi::V1::ServerSearchController < Inapi::ApplicationController 
  def index
    @locations = Location.where(hidden: false).includes(:indices, :certificates, :uptimes, :region)
  end
end
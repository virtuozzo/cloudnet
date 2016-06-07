class Inapi::ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :authenticate_user!

end
# Base Grape class
class Api < Grape::API
  version :v1, using: :accept_version_header
  default_format :json
  format :json
  formatter :json, Grape::Formatter::Roar

  rescue_from RuntimeError do |e|
    error!({ message: { error: 'Internal Server Error. This has been logged.' } }, 500)
  end

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    error!({ message: { error: e } }, 400)
  end

  helpers do
    def current_user
      #error!('Please provide an Authorization header', 401) unless headers.key? 'Authorization'
      @current_user ||= User.api_authorize(headers['Authorization'])
    rescue ActiveRecord::RecordNotFound
      error!('401 Unauthorized', 401)
    end

    def authenticate!
      current_user
    end
  end


  desc 'API version'
  get '/version' do
    { 'version' => 1 }
  end

  # get '/' do
  #   { 'root' => 2 }
  # end

end

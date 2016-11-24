module Squall
  # Squall (the gem used to interface with the OnApp API) uses class
  # variables to define the auth params and server params. Unfortunately
  # this is no good for us because we want different params per request
  # for individual users. After much deliberation, if we monkey patch the
  # request method used by Squall to use our custom auth params then we
  # would have solved the issue on an instance by instance basis

  # Class variables are no good to us when it comes to multithreading. It
  # can lead to race conditions with one param set on one thread and it
  # being overrriden in another causing both calls/threads/workers to fail

  class Base
    def initialize(config)
      @config = config
    end

    def request(request_method, path, options = {})
      check_config

      verify_ssl = ENV['ONAPP_API_ALLOW_INSECURE'] != 'true'
      conn = Faraday.new(url: @config[:uri], ssl: { verify: verify_ssl }) do |c|
        c.basic_auth @config[:user], @config[:pass]
        c.params = (options[:query] || {})
        c.request :url_encoded
        c.adapter :net_http
        c.use Faraday::Response::RaiseError
        c.use Faraday::HttpCache, store: Rails.cache, logger: Rails.logger, shared_cache: false

        if @config[:debug]
          c.use Faraday::Response::Logger
        end
      end

      begin
        response = conn.send(request_method, path)
      rescue Faraday::Error::ClientError => e
        unless build_checker_404?(e)
          ErrorLogging.new.track_exception(
            e,
            extra: {
              request: {
                config: @config,
                options: options
              },
              response: e.response
            }
          )
        end
        raise e
      end

      @success = (200..207).include?(response.env[:status])
      @result  = JSON.parse response.body unless response.body.strip.empty?
    end

    # Strong coupling with the file name of build_checker monitor for vm_monitor_destroy
    def build_checker_404?(e)
      e.is_a?(Faraday::ResourceNotFound) &&
      ::User.find_by(email: 'build_checker_fake_email').try(:onapp_user) == @config[:user] &&
      e.backtrace.join.match(/vm_monitor_destroy/)
    end

    def check_config
      fail NoConfig, 'Configuration must be specified in initialize as a hash' if @config.empty?
    end
  end
end

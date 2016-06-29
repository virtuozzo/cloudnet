module GrapeLogging
  module Loggers
    class SelectedHeaders < GrapeLogging::Loggers::Base

      HTTP_PREFIX = 'HTTP_'.freeze
      LOG_HEADERS = %w( Accept Accept-Version Referer User-Agent Authorization)

      def initialize(log_headers)
        @log_headers = log_headers.in?([nil, :default]) ? LOG_HEADERS : log_headers
      end
      
      def parameters(request, _)
        headers = {}
        
        request.env.each_pair do |k, v|
          next unless k.to_s.start_with? HTTP_PREFIX
          k = k[5..-1].split('_').each(&:capitalize!).join('-')
          next unless k.in? @log_headers
          headers[k] = v
        end

        { headers: headers }
      end


    end
  end
end
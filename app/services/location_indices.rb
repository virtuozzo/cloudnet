class LocationIndices
  def initialize(location)
    @location = location
  end

  def process
    return nil unless hv_group_id
    indices.sort {|a,b| a[:created_at].to_time <=> b[:created_at].to_time }
  end
  
  private
  
    def indices
      stat = Squall::Statistic.new(*squall_params)
      stat.cloud_score(federation_id).map do |index|
        next if index.any? {|k,v| v.is_a?(Fixnum) and v == 0 }
        index.symbolize_keys
      end.compact
    rescue Faraday::Error::ClientError => e
      #TODO: Enable error logs when all locations have performance tests enabled
      #log_error(e)
      []
    end
  
    def federation_id
      hz = Squall::HypervisorZone.new(*squall_params)
      hz.show(hv_group_id)["federation_id"]
    end
  
    def hv_group_id
      @location.hv_group_id
    end
  
    def squall_params
      [uri: ONAPP_CP[:uri], user: ONAPP_CP[:user], pass: ONAPP_CP[:pass]]
    end
    
    def log_error(e)
      ErrorLogging.new.track_exception(
        e,
        extra: {
          current_location: @location,
          source: 'LocationIndices',
          faraday: e.response
        }
      )
    end
end

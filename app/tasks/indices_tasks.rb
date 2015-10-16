class IndicesTasks < BaseTasks

  def perform(action, *args)
    run_task(action, *args)
  end

  private
  
    def update_all_locations
      Location.all.each {|location| location_update(location)}
    end
    
    def location_update(location)
      @location = location
      new_indices.each { |i| @location.indices << prepare_index(i)}
    end

    def new_indices
      return indices unless last_index_created_at = @location.indices.last.try(:created_at).try(:to_time)
      indices.select {|i| i[:created_at].to_time > last_index_created_at}
    end
    
    def indices
      LocationIndices.new(@location).process
    end
    
    def prepare_index(i)
      Index.new(index_cpu: i[:cpu_score], 
                index_iops: i[:disk_score], 
                index_bandwidth: i[:bandwidth_score], 
                created_at: i[:created_at]
               )
    end
    
    def allowable_methods
      [
        :update_all_locations,
        :location_update
      ] + super
    end
end
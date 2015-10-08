class Index < ActiveRecord::Base
  include CloudIndexCalculationTemplate

  belongs_to :location
  after_save :integration_check
  validates :index_cpu, :index_iops, :index_bandwidth, numericality: {greater_than_or_equal_to: 0.0}
  default_scope {order(:created_at)}
  
  MAX_INDICES_PER_LOCATION = 30
  MAX_INDICES_NAMESPACE = "max_indices_cash_namespace"
  CURRENT_INDICES_CACHE = "current_indices_cache"
  SPECIFIC_INDICES_CACHE = "specific_indices_cache"


    def integration_check
      destroy_last_index if indices_number_exceeded?
      update_location_max_attributes if max_attributes_changed?
      invalidate_current_indices_cache if current_indices_changed?
      invalidate_specific_indices_cache
    end

    def indices_number_exceeded?
      number_of_indices > MAX_INDICES_PER_LOCATION
    end
  
    def destroy_last_index
      last_index.destroy
    end
  
    def update_location_max_attributes
      location.update(max_indices_from_collection)
      invalidate_max_indices_cache_namespace
    end
    
    def max_attributes_changed?
      #max_indices_from_collection != current_max_indices
      index_cpu > location.max_index_cpu ||
      index_iops > location.max_index_iops ||
      index_bandwidth > location.max_index_bandwidth
    end

    private 
    
    def number_of_indices
      location.indices.count
    end
    
    def last_index
      location.indices.order(:created_at).first
    end

    def max_indices_from_collection
      @collection_max ||= attributes_hash(
        max_index(:index_cpu),
        max_index(:index_iops),
        max_index(:index_bandwidth)
      )
    end
    
    def max_index(index)
      location.indices.maximum(index)
    end
    
    def current_max_indices
      @current_max ||= attributes_hash(
        location.max_index_cpu,
        location.max_index_iops,
        location.max_index_bandwidth
      )
    end

    def attributes_hash(cpu, iops, bandwidth)
      {
        max_index_cpu: cpu,
        max_index_iops: iops,
        max_index_bandwidth: bandwidth,
      }
    end

    def indices_for_calculation
      self
    end
    
    def calc_indices_update
      ["for_index", Rails.cache.read([SPECIFIC_INDICES_CACHE, id])]
    end
    
    def current_indices_changed?
      location.indices.maximum(:created_at) == created_at
    end
    
    def invalidate_specific_indices_cache
      Rails.cache.write([SPECIFIC_INDICES_CACHE, id], SecureRandom.hex)
    end
    
    def invalidate_current_indices_cache
      Rails.cache.write([CURRENT_INDICES_CACHE, location.id], SecureRandom.hex)
    end
    
    def invalidate_max_indices_cache_namespace
      Rails.cache.write(MAX_INDICES_NAMESPACE, SecureRandom.hex)
    end
end

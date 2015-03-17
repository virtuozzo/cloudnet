module CloudIndexCalculationTemplate

  def cloud_index
    index_scores[:total]
  end

  def index_scores
    Rails.cache.fetch(calc_indices_cache_key) do
      ind = normalized_indices 
      total = ((ind[:cpu] + ind[:iops] + ind[:bandwidth]) / 3.0).round
      ind.merge( {total: total })
    end
  end
  
  def normalized_indices
    indices_hash( normalized_index(:index_cpu),
                  normalized_index(:index_bandwidth),
                  normalized_index(:index_iops))
  end

  def indices_hash(cpu = 0, bw = 0, iops = 0)
    { cpu: cpu || 0, bandwidth: bw || 0, iops: iops || 0}
  end
  
  def normalized_index(index)
    return unless indices_for_calculation
    (indices_for_calculation.send(index) / maxmax_index("max_" + index.to_s) * 100).round
  end
  
  def maxmax_index(index)
    Rails.cache.fetch(maxmax_index_cache_key(index)) {Location.maximum(index).to_f}
  end

  def indices_for_calculation
    raise "deliver Index class object for which calculations are performed"
  end

  private
  
  def maxmax_index_cache_key(index)
    [index, namespace_cache_key]
  end
  
  def calc_indices_cache_key
    ["index_scores", id, calc_indices_update, namespace_cache_key]
  end
  
  def calc_indices_update
    raise "update cache key for calculated Index object"
  end
  
  def namespace_cache_key
    Rails.cache.read(Index::MAX_INDICES_NAMESPACE)
  end
end
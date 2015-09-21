class UtmTracker < Struct.new(:params)
  
  def self.extract_properties(params)
    new(params.symbolize_keys).utm_hash
  end
  
  def utm_hash
    {
      utm_source: params[:utm_source],
      utm_medium: params[:utm_medium],
      utm_campaign: params[:utm_campaign],
      utm_content: params[:utm_content],
      utm_term: params[:utm_term]
    }
  end
end
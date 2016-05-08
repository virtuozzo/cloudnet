class SiftLabel
  include Sidekiq::Worker

  def perform(label, user_id, properties = nil)
    return false if KEYS[:sift_science][:api_key].blank?
    begin
      if label == "create"
        return false if properties.nil?
        SiftTasks.new.perform(:create_label, user_id, properties)
      elsif label == "remove"
        SiftTasks.new.perform(:remove_label, user_id)
      end
    rescue Exception => e
      ErrorLogging.new.track_exception(e, extra: { source: 'SiftLabel', label: label, user_id: user_id, properties: properties })
    end
  end
end

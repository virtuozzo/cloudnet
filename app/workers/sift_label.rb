class SiftLabel
  include Sidekiq::Worker

  def perform(label, user_id, properties = nil)
    begin
      if label == "create"
        return false if properties.nil?
        task = SiftClientTasks.new.perform(:create_label, user_id, properties)
      elsif label == "remove"
        task = SiftClientTasks.new.perform(:remove_label, user_id)
      end
      return if task.nil?
      
      if SiftScience::Client::RETRY_ERROR_CODES.include? task.api_status
        SiftLabel.perform_in(SiftScience::Client::API_INTERVAL.seconds, label, user_id, properties)
      elsif SiftScience::Client::LOG_ERROR_CODES.include? task.api_status
        raise task.api_error_message
      end
    rescue StandardError => e
      ErrorLogging.new.track_exception(e,
        extra: {
          source: 'SiftLabel',
          label: label,
          user_id: user_id,
          properties: properties,
          api_status: task.try(:api_status),
          error_message: task.try(:api_error_message)
        }
      )
    end
  end
end

class CreateSiftEvent
  include Sidekiq::Worker
  sidekiq_options queue: 'create_sift_event'

  def perform(event, properties)
    return false if properties.nil?
    begin
      task = SiftClientTasks.new.perform(:create_event, event, properties)
      return if task.nil?
      
      if SiftScience::Client::RETRY_ERROR_CODES.include? task.api_status
        CreateSiftEvent.perform_in(SiftScience::Client::API_INTERVAL.seconds, event, properties)
      elsif SiftScience::Client::LOG_ERROR_CODES.include? task.api_status
        raise task.api_error_message
      end
      
    rescue StandardError => e
      ErrorLogging.new.track_exception(e,
        extra: {
          source: 'CreateSiftEvent',
          event: event,
          properties: properties,
          api_status: task.try(:api_status),
          error_message: task.try(:api_error_message)
        }
      )
    end
  end
end

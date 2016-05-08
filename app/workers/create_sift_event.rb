class CreateSiftEvent
  include Sidekiq::Worker

  def perform(event, properties)
    return false if KEYS[:sift_science][:api_key].blank? || properties.nil?
    begin
      SiftTasks.new.perform(:create_event, event, properties)
    rescue Exception => e
      ErrorLogging.new.track_exception(e, extra: { source: 'CreateSiftEvent', event: event, properties: properties })
    end
  end
end

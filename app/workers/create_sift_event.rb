class CreateSiftEvent
  include Sidekiq::Worker

  def perform(event, properties)
    return false if properties.nil?
    begin
      SiftClientTasks.new.perform(:create_event, event, properties)
    rescue Exception => e
      ErrorLogging.new.track_exception(e, extra: { source: 'CreateSiftEvent', event: event, properties: properties })
    end
  end
end

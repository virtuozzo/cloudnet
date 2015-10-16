class EventsController < ApplicationController
  include Tubesock::Hijack
  
  def event
    hijack do |tubesock|
      tubesock.onmessage do |m|
        case m
        when "getUnbilledRevenue"
          unbilled_revenue(tubesock)
        end
      end
    end
  end
  
  def unbilled_revenue(tubesock)
    thread = Thread.new do
      Thread.current.abort_on_exception = true
      result = Rails.cache.fetch('total_unbilled_revenue', expires_in: 1.hour) do
        UserTasks.total_unbilled_revenue
      end
      tubesock.send_data(result)
    end

    tubesock.onclose do
      thread.kill
    end
  end
end
require 'segment/analytics'

class Analytics
  def self.track(user, events = {})
    user_traits = user ? {
      user_id: user.id,
      username: user.email,
      context: { traits: { email: user.email, name: user.full_name } }
      } : {anonymous_id: 'guest'}
      
    service.track(events.merge(user_traits))
  end

  def self.service
    Segment::Analytics.new(
      write_key: KEYS[:analytics][:token],
      on_error: proc { |_status, msg| print msg }
    )
  end
end

require 'segment/analytics'

class Analytics
  def self.track(user, events = {}, anonymous_id = nil, req = nil)
    return true if KEYS[:analytics][:token].nil?
    user_traits = user ? {
      user_id: user.id,
      context: { traits: { email: user.email, name: user.full_name } }
      } : {anonymous_id: anonymous_id ? anonymous_id : 'guest',
           context: {ip: req.try(:remote_ip), userAgent: req.try(:user_agent) }
          }
      
    service.track(events.merge(user_traits))
  end

  def self.service
    Segment::Analytics.new(
      write_key: KEYS[:analytics][:token],
      on_error: proc { |_status, msg| print msg }
    )
  end
end

json.extract! reply, :id, :ticket_id, :sender
json.created_at reply.created_at.iso8601
json.updated_at reply.updated_at.iso8601
json.body markdown(reply.body, false)
json.created_ordinal reply.created_at.to_formatted_s(:long_ordinal)
unless reply.user.nil?
  json.image gravatar_image(current_user, 64)
  json.staff_reply false
else
  json.image 'icon-support.png'
  json.staff_reply true
end

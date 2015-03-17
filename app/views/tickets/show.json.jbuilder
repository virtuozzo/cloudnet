json.extract! @ticket, :id, :subject, :server, :status, :reference
json.created_at @ticket.created_at.iso8601
json.updated_at @ticket.updated_at.iso8601
json.username current_user.full_name
json.staff_reply false
json.image gravatar_image(current_user, 64)
json.created_ordinal @ticket.created_at.to_formatted_s(:long_ordinal)
json.body markdown(@ticket.body, false)
json.replies do
  json.partial! 'ticket_replies', replies: @ticket_replies
end

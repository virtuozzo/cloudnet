json.array! replies do |reply|
  json.partial! 'ticket_reply', reply: reply
end

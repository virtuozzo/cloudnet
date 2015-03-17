json.array! @events do |event|
  json.action event.action
  json.created_at event.transaction_created
  json.updated_at event.transaction_updated
  json.status event.status
end

json.array!(@tickets) do |ticket|
  json.extract! ticket, :id, :subject, :body, :server, :reference
  json.url ticket_url(ticket, format: :json)
end

@app.service "Locations", ["$resource", ($resource) ->
  $resource "/api/v1/server_search", null
]

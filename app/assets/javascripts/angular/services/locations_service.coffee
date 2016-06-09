@app.service "Locations", ["$resource", ($resource) ->
  $resource "/inapi/v1/server_search", null
]

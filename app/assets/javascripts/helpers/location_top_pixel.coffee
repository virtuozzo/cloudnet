class helpers.LocationTopPixel
  constructor: (@state) ->

  forLocation: (id) ->
    @getTopPixel(@listPosition(id))

  listPosition: (id) ->
    _(@state.filteredLocationsArray).findIndex (loc) -> loc.id == id
    
  getTopPixel: (pos) ->
    switch pos
      when 0 then 0
      else 160 + (pos-1) * 155

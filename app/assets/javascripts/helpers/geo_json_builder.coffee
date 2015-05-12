class helpers.GeoJsonBuilder
  constructor: (locations, @inactivePin) ->
    @locations = locations
    
  generate: ->
    _.map @locations, (location) =>
      # Copy the GeoJSON template, clone attributes and then set attributes based on location
      data = @geoJson(location)
      data.properties = _.extend location, data.properties
      data
    
  geoJson: (loc) ->
    type: 'Feature'
    geometry:
      type: 'Point'
      coordinates: [loc.longitude, loc.latitude]
    properties:
      icon: @defaultIcon()
      
  defaultIcon: ->
    iconUrl: @inactivePin
    iconSize: ['26', '32']
    iconAnchor: ['13', '32']
    popupAnchor: [-2, -35]
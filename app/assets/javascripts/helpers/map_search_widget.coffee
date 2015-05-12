class helpers.MapSearchWidget
  constructor: (@scope, @mapElem, @ctrl, @state, @keys, @popup, @pins) ->
    @getTopPixel = new helpers.LocationTopPixel(@state)
    @initialize500px()
    @initializeMap()
    @attachMapToModelChange()
    
  initialize500px: ->
    _500px.init
      sdk_key: @keys.fiveHundredPxKey

  initializeMap: ->
    @map = L.mapbox.map @mapElem[0], @keys.mapboxKey,
      accessToken: @keys.mapboxPublicToken,
      minZoom: 2,
      maxZoom: 8
      closePopupOnClick: false
    @map.setView [40.0, -20.0], 2
    
  attachMapToModelChange: ->
    @ctrl.$render = =>
      @removeExistingMarkers()
      geoJsonLayer = @prepareGeoJsonLayer( @buildGeoJsonData() )
      @addLayersToMap(geoJsonLayer)

  addLayersToMap: (layer) ->
    @scope.clusters = @defineClusterGroup()
    @scope.clusters.addLayer(layer)
    @map.addLayer(@scope.clusters)

  defineClusterGroup: ->
    new L.MarkerClusterGroup
      maxClusterRadius: 20
      animateAddingMarkers: true

  prepareGeoJsonLayer: (geoJson) ->
    L.geoJson geoJson,
      onEachFeature: (feature, layer) =>
        @attachPhotoToPopup(feature.properties, layer)
        @attachClickHandler(layer)
        layer.setIcon(L.icon(feature.properties.icon))

  removeExistingMarkers: ->
    @map.removeLayer(@scope.clusters) if @scope.clusters
    
  buildGeoJsonData: ->
    new helpers.GeoJsonBuilder(@ctrl.$viewValue, @pins.inactivePin).generate()
    
  attachPhotoToPopup: (properties, layer) ->
    photoBuilder = new helpers.PhotoBuilder(properties, layer)
    photoBuilder.fetchPhoto().then (photo) =>
      data   = photo.marker.feature.properties
      newContent = @popup({photo: photo, data: data})
      photo.marker.bindPopup(newContent)
  
  attachClickHandler: (marker) ->
    marker.on 'click', (e) =>
      marker  =   e.target
      icon    =   marker.options.icon.options
      data    =   marker?.feature?.properties
      el = $('map-widget .message')
      el.addClass('open') 
      el.find('location-widget').addClass('show')
      @scope.$apply(
        @state.mapActiveLocation = _(@state.filteredLocationsArray).find (loc) -> loc.id == data.id
      )
  toggleMarkerPin: (icon, marker) ->
    if icon.iconUrl is inactive_pin
      return marker.setIcon(L.icon(active_icon))

    else if icon.iconUrl is active_pin
      return marker.setIcon(L.icon(default_icon))

  
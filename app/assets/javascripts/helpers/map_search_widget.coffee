class helpers.MapSearchWidget
  constructor: (@scope, @mapElem, @ctrl, @state, @filter, @keys, @popup) ->
    @initialize500px()
    @initializeMap()
    @attachMapToModelChange()
    
  initialize500px: ->
    _500px.init
      sdk_key: @keys.fiveHundredPxKey

  initializeMap: ->
    @map = L.mapbox.map @mapElem[0], @keys.mapboxKey,
      accessToken: @keys.mapboxPublicToken,
      minZoom: 1,
      maxZoom: 8
      closePopupOnClick: false
    @map.setView [40.0, -20.0], 2
    
  attachMapToModelChange: ->
    @ctrl.$render = =>
      @removeExistingMarkers()
      geoJsonLayer = @prepareGeoJsonLayer( @buildGeoJsonData() )
      @scope.clusters = @defineClusterGroup()
      @scope.clusters.addLayer(geoJsonLayer)
      @map.addLayer(@scope.clusters)

  removeExistingMarkers: ->
    @map.removeLayer(@scope.clusters) if @scope.clusters
    
  buildGeoJsonData: ->
    new helpers.GeoJsonBuilder(@ctrl.$viewValue).generate()
    
  defineClusterGroup: ->
    new L.MarkerClusterGroup
      maxClusterRadius: 20
      animateAddingMarkers: true
      
  prepareGeoJsonLayer: (geoJson) ->
    L.geoJson geoJson,
      onEachFeature: (feature, layer) =>
        #rect    = generateRect d.latitude, d.longitude
  
        photoBuilder = new helpers.PhotoBuilder(feature.properties, layer)
        photoBuilder.fetchPhoto().then (photo) =>
          #console.log @popup({photo: photo})
          data   = photo.marker.feature.properties
          newContent = @popup({photo: photo, data: data})
          photo.marker.bindPopup(newContent)

        layer.setIcon(L.icon(feature.properties.icon))
        layer.bindPopup('')
        layer.on 'click', (e) ->
          marker  =   e.target
          icon    =   marker.options.icon.options
          data    =   marker?.feature?.properties
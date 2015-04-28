class helpers.MapSearchWidget
  constructor: (@scope, @mapElem, @ctrl, @state, @filter, @keys) ->
    @initializeMap()
    @attachMapToModelChange()
    
  initializeMap: ->
    @map = L.mapbox.map @mapElem[0], @keys.mapboxKey,
      accessToken: @keys.mapboxPublicToken,
      minZoom: 1,
      maxZoom: 8
      closePopupOnClick: false
    @map.setView [40.0, -20.0], 2
    
  attachMapToModelChange: ->
    @ctrl.$render = =>
      @map.removeLayer(@scope.clusters) if @scope.clusters
      geoJson = new helpers.GeoJsonBuilder(@ctrl.$viewValue).generate()
      geoJsonLayer = L.geoJson geoJson,
        onEachFeature: (feature, layer) ->
          layer.on 'click', (e) ->
            marker  =   e.target
            icon    =   marker.options.icon.options
            data    =   marker?.feature?.properties
            
      @scope.clusters = new L.MarkerClusterGroup
        maxClusterRadius: 20
        animateAddingMarkers: true
      @scope.clusters.addLayer(geoJsonLayer)
      @map.addLayer(@scope.clusters)

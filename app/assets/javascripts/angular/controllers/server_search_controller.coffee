@app.controller "ServerSearchCtrl",
  class ServerSearchCtrl
    @$inject: ['ServerSearchState', 'Locations', 'Packages'] 
    
    constructor: (@state, @locationsQuery, @packages) ->
      @initializeLocations()
      @mapVisible = true
      
    showMap: ->
      console.log 'show map'
      @mapVisible = true
      
    hideMap: ->
      console.log 'hide map'
      @mapVisible = false
      
    initializeLocations: ->
      @locationsQuery.query (result) =>
        @state.locations.push(new models.Location(loc)) for loc in result
        @state.filteredLocationsArray = @state.filteredSortedLocations()
        
    showVpsLocations: ->
      !@packages.activePackage and
      (Object.keys(@state.cloudVpsFilter).length is 0 or
       @state.cloudVpsFilter.budgetVps)

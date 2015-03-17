@app.controller "ServerSearchCtrl",
  class ServerSearchCtrl
    @$inject: ['ServerSearchState', 'Locations', 'Packages'] 
    
    constructor: (@state, @locationsQuery, @packages) ->
      @initializeLocations()

    locationSort: ->
      [(location) =>
        switch @sortBy.field
          when 'price' then location.pricePerHour(@state.counts)
          when 'cloudIndex' then location.cloudIndex
          when 'uptime' then @state.currentUptime(location)
       ,'city']  
      
    initializeLocations: ->
      @locations = []
      @sortBy = {field: 'price', rev: false}
      @locationsQuery.query (result) =>
        @locations.push(new models.Location(loc)) for loc in result

    showVpsLocations: ->
      !@packages.activePackage and
      (Object.keys(@state.cloudVpsFilter).length is 0 or
       @state.cloudVpsFilter.budgetVps)

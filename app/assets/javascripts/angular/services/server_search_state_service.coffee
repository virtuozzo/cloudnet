@app.service "ServerSearchState", ["$rootScope", "$filter",
  class ServerSearchState
    constructor: (@scope, @filter) ->
      @setVariables()
      @registerWatch()

    setVariables: ->
      @sortBy = {field: 'price', rev: false}
      @slidersEnabled = true
      @cloudVpsFilter = {}
      @regionFilter = {}
      @locations = []
      @filteredLocationsArray = []
      @mapVisible = true
      @counts = 
        cpu:  @initialValue('cpu')
        mem:  @initialValue('mem')
        disk: @initialValue('disk')
        index: 0
        uptime: 0
      
    registerWatch: ->
      @scope.$watchCollection => 
        [@cloudVpsFilter, @packageFilter, @regionFilter, @counts, @sortBy, @locations]
      , =>
        @filteredLocationsArray = @filteredSortedLocations()
        
    initialValue: (param) ->
      $('.filters').data(param) || 1
      
    getIntegerCounts: ->
      mem:  parseInt(@counts.mem,  10) 
      cpu:  parseInt(@counts.cpu,  10) 
      disk: parseInt(@counts.disk, 10)
      
    cloudIndexUptimeFilter: (location, ind) =>
      location.cloudIndex >= @counts.index && @currentUptime(location) >= @counts.uptime

    currentUptime: (location) ->
      data = location?.indices
      if data?.length > 0
        data[data.length-1].indexUptime 
      else
        0
        
    locationSort: ->
      [(location) =>
        switch @sortBy.field
          when 'price' then location.pricePerHour(@counts)
          when 'cloudIndex' then location.cloudIndex
          when 'uptime' then @currentUptime(location)
       ,'city']
       
    filteredSortedLocations: ->
      loc = @filter('filter')(@locations, @cloudVpsFilter)
      loc = @filter('filter')(loc, @regionFilter)
      loc = @filter('filter')(loc, @packageFilter)
      loc = @filter('filter')(loc, @cloudIndexUptimeFilter)
      @filter('orderBy')(loc, @locationSort(), @sortBy.rev)
]
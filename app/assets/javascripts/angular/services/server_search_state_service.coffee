@app.service "ServerSearchState",
  class ServerSearchState
    constructor: ->
      @setVariables()

    setVariables: ->
      @slidersEnabled = true
      @cloudVpsFilter = {}
      @counts = 
        cpu:  @initialValue('cpu')
        mem:  @initialValue('mem')
        disk: @initialValue('disk')
        index: 0
        uptime: 0
        
    initialValue: (param) ->
      $('.filters').data(param) || 1
      
    getIntegerCounts: ->
      mem:  parseInt(@counts.mem,  10) 
      cpu:  parseInt(@counts.cpu,  10) 
      disk: parseInt(@counts.disk, 10)
      
    cloudIndexUptimeFilter: (location, ind) =>
      location.cloudIndex >= @counts.index && @currentUptime(location) >= @counts.uptime

    currentUptime: (location) ->
      data = location.indices
      if data.length > 0
        data[data.length-1].indexUptime 
      else
        0
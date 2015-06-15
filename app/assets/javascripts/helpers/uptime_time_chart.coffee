class helpers.UptimeTimeChart extends helpers.TimeChart
  constructor: (@elem, @data) ->
    super(@elem, @data)

  xRange: ->
    [20,150]
    
  yDomain: ->
    [98,100]
    
  yTicks: ->
    [98,99,100]
    
  viewBoxValues: ->
    "0 0 155 65"
  
  dataName: ->
    "indexUptime"
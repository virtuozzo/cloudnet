class helpers.UptimeTimeChart extends helpers.TimeChart
  constructor: (@elem, @data) ->
    super(@elem, @data, false, true)

  xRange: ->
    [20,150]
    
  yDomain: ->
    [0,100]
    
  yTicks: ->
    [0,25,50,75,100]
    
  viewBoxValues: ->
    "0 0 155 65"
  
  dataName: ->
    "uptime"
    
  interpolation: ->
    "linear"
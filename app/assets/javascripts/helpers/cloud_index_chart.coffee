class helpers.CloudIndexChart extends helpers.TimeChart
  constructor: (@elem, @data, @popup) ->
    super(@elem, @data, @popup)

  xRange: ->
    [20,100]
    
  yDomain: ->
    [0,100]
    
  yTicks: ->
    [0,50,100]
    
  viewBoxValues: ->
    "0 0 105 65"
  
  dataName: ->
    "cloudIndex"
class helpers.TimeChart
  constructor: (@elem, @data, @popup) ->
    @initialize()
    @addTooltips() if @popup

  draw: ->
    #@addXaxis()
    @addYaxis()
    @drawChart()

  drawChart: ->
    @drawPath()
    @appendCircles()
    @drawCircles()

  appendCircles: ->
    @chart.selectAll("circle").data(@data)
          .enter().append("circle")
      
  drawCircle: (el, x) ->
    el.attr("cx", (d) => @xScale(x))
      .attr("cy", (d) => @yScale(d[@dataName()]))
      .attr("r", 2)
    @addCircleTooltip(el) if @popup
    
  drawCircles: ->
    elems = @chart.selectAll("circle")
    last = elems.size()
    firstCircle = d3.select(elems[0][0])
    lastCircle = d3.select(elems[0][last-1]) if last > 1
    
    @drawCircle(firstCircle, 1)
    @drawCircle(lastCircle, last) if lastCircle

  addCircleTooltip: (el) ->
    el.on('mouseover', @tip.show)
      .on('mouseout', @tip.hide)

  prepareLinePath: ->
    xPos = 0
    @line = d3.svg.line()
      .x( (d) => @xScale (xPos += 1)) 
      .y( (d) => @yScale(d[@dataName()]))
      .interpolate("cardinal")
  
  drawPath: ->
    @prepareLinePath()
    @chart.append("path")
    .attr("d", @line(@data))
    .attr("class", "line")
      
  addXaxis: ->
    @chart.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0, 65)").call(@xAxis)

  addYaxis: ->
    @chart.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(15, 0)").call(@yAxis)
    
  initialize: ->
    d3.select(@elem).selectAll("*").remove()
    @format = d3.time.format("%b %d")
    @chart = d3.select(@elem).append("svg")
    @yScale = d3.scale.linear().range([60,5]).domain(@yDomain());
    @xScale = d3.time.scale().range(@xRange()).domain(@xDomain())
    @xAxis = d3.svg.axis().scale(@xScale).orient("bottom")
             .tickFormat(d3.time.format("%b %d")).ticks(4)
    @yAxis = d3.svg.axis().scale(@yScale).orient("left").tickValues(@yTicks())
             .innerTickSize([2]).outerTickSize([2]).tickPadding([1])
    @chart.attr("viewBox", @viewBoxValues())
    
  addTooltips: ->
    @tip = @prepareTooltips()
    @chart.call(@tip)
    
  prepareTooltips: ->
    d3.tip()
      .attr('class', 'd3-tip')
      .html (d) => @popup(data: d)
      .offset [0,9]
      .direction 'e'

  xRange: ->
    throw "implement me"
    
  xDomain: ->
    [1, @data.length]
    
  yDomain: ->
    throw "implement me"

  yTicks: ->
    throw "implement me"
    
  viewBoxValues: ->
    throw "implement me"
  
  dataName: ->
    throw "implement me"
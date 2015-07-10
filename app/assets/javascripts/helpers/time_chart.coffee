class helpers.TimeChart
  constructor: (@elem, @data, @popup) ->
    @initialize()
    @addTooltips() if @popup
    @appendData()

  draw: ->
    @drawChart()
    #@addXaxis()
    @addYaxis()
    
  appendData: ->
    @chart
      .attr("viewBox", @viewBoxValues())
      .selectAll("circle").data(@data)
      .enter().append("circle")
      
  drawChart: ->
    @drawCircles()
    @prepareLinePath()
    @drawPath()

  drawCircles: ->
    el = @chart.select("circle")
               .attr("cx", (d) => @xScale(1))
               .attr("cy", (d) => @yScale(d[@dataName()]))
               .attr("r", 2)
    @addCircleTooltip(el) if @popup

    elem = @chart.selectAll("circle")
    last = elem.size()
    if last > 1
      el = d3.select(elem[0][last-1])
             .attr("cx", (d) => @xScale(last))
             .attr("cy", (d) => @yScale(d[@dataName()]))
             .attr("r", 2)
      @addCircleTooltip(el) if @popup
  
  addCircleTooltip: (el) ->
    el.on('mouseover', @tip.show)
      .on('mouseout', @tip.hide)
      
  prepareLinePath: ->
    xPos = 0
    @line = d3.svg.line()
      .x( (d) => @xScale (xPos += 1)) 
      .y( (d) => @yScale(d[@dataName()]))
      .interpolate(@interpolation())
  
  drawPath: ->
    @chart.insert("path",":first-child")
    .attr("d", @line(@data))
    .attr("class", "line")
      
  addXaxis: ->
    @chart.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0, 45)").call(@xAxis)

  addYaxis: ->
    @chart.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(15, 0)").call(@yAxis)
    
  initialize: ->
    d3.select(@elem).selectAll("*").remove()
    @chart = d3.select(@elem).append("svg")
    @yScale = d3.scale.linear().range([60,5]).domain(@yDomain());
    @xScale = d3.scale.linear().range(@xRange()).domain([1, @data.length])
    @xAxis = d3.svg.axis().scale(@xScale).tickValues([])
    @yAxis = d3.svg.axis().scale(@yScale).orient("left").tickValues(@yTicks())
             .innerTickSize([2]).outerTickSize([2]).tickPadding([1])
  
  addTooltips: ->
    @tip = @prepareTooltips()
    @chart.call(@tip)
    
  prepareTooltips: ->
    d3.tip()
      .attr('class', 'd3-tip')
      .html (d) => @popup(data: d)
      .offset [0,9]
      .direction 'e'
      
  interpolation: ->
    "cardinal"
    
  xRange: ->
    throw "implement me"
    
  yDomain: ->
    throw "implement me"

  yTicks: ->
    throw "implement me"
    
  viewBoxValues: ->
    throw "implement me"
  
  dataName: ->
    throw "implement me"
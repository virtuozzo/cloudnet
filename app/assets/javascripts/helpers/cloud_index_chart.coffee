class helpers.CloudIndexChart
  constructor: (@elem, @data) ->
    @initialize()
    @appendData()
    
  draw: ->
    @drawChart()
    #@addXaxis()
    @addYaxis()
    
  appendData: ->
    @chart
      .attr("viewBox", "0 0 105 65")
      .selectAll("circle").data(@data)
      .enter().append("circle")
      
  drawChart: ->
    @drawCircles()
    @prepareLinePath()
    @drawPath()

  drawCircles: ->
    @chart.select("circle")
      .attr("cx", (d) => @xScale(1))
      .attr("cy", (d) => @yScale(d.cloudIndex))
      .attr("r", 2)
      
    elem = @chart.selectAll("circle")
    last = elem.size()
    if last > 1
      d3.select(elem[0][last-1])
        .attr("cx", (d) => @xScale(last))
        .attr("cy", (d) => @yScale(d.cloudIndex))
        .attr("r", 2)
      
  
  prepareLinePath: ->
    xPos = 0
    @line = d3.svg.line()
      .x( (d) => @xScale (xPos += 1)) 
      .y( (d) => @yScale(d.cloudIndex))
      .interpolate("cardinal")
  
  drawPath: ->
    @chart.append("path")
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
    @chart = d3.select(@elem).append("svg")
    @yScale = d3.scale.linear().range([60,5]).domain([0,100]);
    @xScale = d3.scale.linear().range([20,100]).domain([1, @data.length])
    @xAxis = d3.svg.axis().scale(@xScale).tickValues([])
    @yAxis = d3.svg.axis().scale(@yScale).orient("left").tickValues([0,50,100])
             .innerTickSize([2]).outerTickSize([2]).tickPadding([1])
class helpers.UptimeTimeChart extends helpers.TimeChart

  drawChart: ->
    @drawArea()
    @drawLines()
    super
    @addXaxis()
    @addXLabel()
    @addYLabel()

    
  prepareLinePath: ->
    @line = d3.svg.line()
      .x( (d) => @xScale (d.date)) 
      .y( (d) => @yScale(d.uptime))
      .interpolate("linear")
      
  prepareArea: ->
    @area = d3.svg.area()
      .x( (d) => @xScale (d.date))
      .y0((d) => @yScale(0))
      .y1((d) => @yScale(d.uptime))
      
  drawArea: ->
    @prepareArea()
    @chart.append("path")
    .attr("d", @area(@data))
    .attr("class", "area")
      
  drawCircles: ->
    @chart.selectAll("circle")
               .attr("cx", (d) => @xScale(d.date) if d.uptime < 100)
               .attr("cy", (d) => @yScale(d.uptime) if d.uptime < 100)
               .attr("r",  (d) -> 1.5 if d.uptime < 100)
               .style("fill", (d) =>  @colorUptime(d.uptime))

  drawLines: ->
   @chart.selectAll("line.low-uptime").data(@downtimeData())
         .enter().append("line")
         .attr("x1", (d) => @xScale(d.date))
         .attr("y1", (d) => @yScale(d.uptime))
         .attr("x2", (d) => @xScale(d.date))
         .attr("y2", (d) => @yScale(0))
         .attr("stroke-width", 0.5)
         .attr("stroke", (d) => @colorUptime(d.uptime))
         .attr("class", "low-uptime")
    
  addXLabel: ->
    @chart.select(".x.axis").append("text")
      .text("Uptime: last #{@data.length} days")
      .attr("x", 65)
      .attr("y", 20)
      
  addYLabel: ->
    @chart.select(".y.axis").append("text")
      .text("% of day")
      .attr("transform", "rotate (-90, -11, 0) translate(-55)")
      
  colorUptime: (uptime) ->
    switch 
      when uptime <= 70 then "Red"
      when uptime <= 90 then "Orange"
      when uptime < 100 then "Yellow"
      
  downtimeData: ->
    _(@data).filter (d) -> d.uptime < 100
    
  xRange: ->
    [20,150]
    
  xDomain: ->
    return [] if @data.length < 1
    [@data[0].date, @data[@data.length-1].date]
    
  yDomain: ->
    [0,100]
    
  yTicks: ->
    [0,25,50,75,100]
    
  viewBoxValues: ->
    "0 0 155 95"
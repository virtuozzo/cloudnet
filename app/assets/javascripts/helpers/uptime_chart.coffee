class helpers.UptimeChart
  startingUptime: 98
  
  constructor: (@elem, @data) ->
    @initialize()
    
  draw: ->
    @drawArc()
    @addText()
    
  drawArc: ->
    @chart
      .datum({endAngle: 0})
      .attr("d", @arc())
      .attr("transform", "translate(5,5)")
      .transition()
        .duration(5000)
        .attrTween "d", @arcTween
    
  arcTween: (d) =>
    (t) =>
      d.endAngle = d3.interpolate(d.endAngle, @endAngle())(t)
      @arc()(d)
        
  arc: ->
    d3.svg.arc()
      .innerRadius(4.2)
      .outerRadius(4.5)
      .startAngle(0)
      
  addText: ->
    uptimeVal = d3.select(@elem).select("svg")
      .append("text")
      .text(@roundedUptime() + "%")
      
    uptimeVal
      .attr("class", "number")
      .attr("x", @centerValue(uptimeVal))
      .attr("y", 5)
      .attr("opacity", 0)
      .transition()
        .delay(800)
        .duration(1000)
        .attrTween "opacity", -> (t)->t
        
    label = d3.select(@elem).select("svg")
      .append("text")
      .text("UPTIME")
      
    label
      .attr("x", @centerValue(label))
      .attr("y", 7)
      .attr("opacity", 0)
      .transition()
        .delay(800)
        .duration(1000)
        .attrTween "opacity", -> (t)->t
        
  centerValue: (el) ->
    5 - el.node().getComputedTextLength() / 2

  endAngle: ->
    return 0 if @data < @startingUptime
    2 * Math.PI * (@roundedUptime() - @startingUptime) / (100 - @startingUptime)
    
  roundedUptime: ->
    parseInt(@data * 1000, 10) / 1000
    
  initialize: ->
    @chart = d3.select(@elem).append("svg")
      .attr("viewBox", "0 0 10 10")
      .append("path")

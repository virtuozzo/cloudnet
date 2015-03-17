createPaygPie = (statistic, donut = false) ->
  colours = ["#1f77b4", "#ff7f0e"]
  d3.scale.colours = -> return d3.scale.ordinal().range(colours)
  nv.addGraph () ->
    svg = d3.select(".jg-chart svg")
    chart = nv.models.pieChart()
    .x (d) -> return d.name
    .y (d) -> return d.y
    .color(d3.scale.colours().range())
    .donut(donut)
    .showLabels(false)
    .showLegend(false)
    .valueFormat(d3.format("0d"))

    svg.datum(statistic)
    .transition().duration(1200)
    .call(chart)

    nv.utils.windowResize(chart.update)
    return chart
window.createPaygPie = createPaygPie

$ ->
  createPaygPie(payg_stats, true)

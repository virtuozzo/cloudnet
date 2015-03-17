$ ->
  tooltip = (d) ->
    """
    #{new Date d.data.key}
    <p>
    CPU Usage: #{d.data.value}
    </p>
    """

  usages = _.map cpu_usages, (usage) ->
    {
      date: new Date(usage["created_at"]).getTime()
      usage: parseInt(usage["cpu_time"])
    }

  graph = new DCGraph(
    selector: '#jg-cpu-usages',
    data: usages,
    statsYData: [{
      yData: (d) -> d.usage,
    }],
    overviewYData: (d) -> d.usage,
    tooltip_function: tooltip
  )

  graph.statsChart.yAxisLabel('CPU Usage')
  graph.render()

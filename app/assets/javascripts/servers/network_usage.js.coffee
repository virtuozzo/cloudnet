
$ ->
  tooltip = (d) ->
    """
    <strong>
      #{d.layer}
    </strong>
    #{new Date d.data.key}
    <p>
    Usage (Mbps): #{d.data.value.toFixed(4)}
    </div>
    """

  usages = _.map network_usages, (usage) ->
    {
      date: new Date(usage["created_at"]).getTime()
      sent: (parseInt(usage["data_sent"]) / (1024.0 * 1024.0))
      received: (parseInt(usage["data_received"]) / (1024.0 * 1024.0))
    }

  lines = [
    {
      name: 'Sent data',
      yData: (d) -> d.sent,
      colour: '#C47FE3'
    },
    {
      name: 'Received data',
      yData: (d) -> d.received,
      colour: '#F7772B'
    }
  ]

  graph = new DCGraph(
    selector: '#jg-network-usages',
    data: usages,
    statsYData: lines,
    overviewYData: (d) -> d.sent + d.received,
    tooltip_function: tooltip
  )

  graph.statsChart.yAxisLabel('Network Usage (Mbps)')
  # min = _.max(usages, (u) -> u.sent)
  # max = _.max(usages, (u) -> u.received)
  # graph.statsChart.yAxis().tickValues([min.sent, 0.0, max.received])
  graph.render()

$ ->

  statsChart = null
  overviewChart = null

  $jgChart = $('.jg-chart')

  # Pie-chart tooltip
  tip = d3.tip().attr('class', 'd3-tip').html((d) ->
    data     = d.data
    template = d.data.template
    return """
      <div class="jg-tooltip-body">
        <div class="server-tooltip-header">
          <h2 class="pure-u icon-cloud jg-icon">#{data.name}</h2>
          <span class="pure-u tags #{data.state}">#{data.state}</span>
        </div>
        <div class="server-tooltip-body pure-g">
          <div class="os x32 os-#{template.os_distro} pure-u-1-8"></div>

          <ul class="server-info pure-u-7-8">
            <li class="pure-u-1-2">#{template.name}</li>
            <li class="pure-u-1-2 nation">
              <img src="/assets/images/flags/flat/24/#{data.location.country}.png"/>
              #{data.location.city}, #{data.location.country}
            </li>
            <li class="pure-u-1-2">#{data.memory} MB</li>
            <li class="pure-u-1-2">#{data.cpus} Core(s)</li>
            <li class="pure-u-1-2">#{data.disk_size} GB</li>
              <li class="pure-u-1-2">#{data.bandwidth} GB</li>
          </ul>

        </div>
      </div>
      """ if template
  )

  statsGraph = () ->
    no_data_html =
     """
       <div class="no-data">
         <p>You haven't created any servers yet</p>
          <div class="jg-widget-controls">
            <a href="/servers/create" class="jg-button-lilac jg-new-button">New Server</a>
          </div>
       </div>
     """

    # Prepare the cpuStats array for use by dc/crossfilter
    # Arguably this should be done server-side
    cpuStats = []
    # `stats` is set by hard-coded script tags in views/dashboard/index
    @servers = stats.stats.cpu_stats
    defaults = {}
    _.each @servers, (server) -> defaults[server.name] = 0
    _.each @servers, (server) =>
      _.each server.cpu_usages, (usage) =>
        datapoint = {}
        _.defaults(datapoint, defaults) # Ensure that every date has stats for every server
        datapoint['date'] = new Date(usage["created_at"]).getTime()
        datapoint[server.name] = parseInt(usage["cpu_time"])
        cpuStats.push datapoint

    tooltip = (datapoint) ->
      """
        <strong>
          #{datapoint.layer}
        </strong>
        #{new Date datapoint.data.key}
        <p>
        CPU Usage: #{datapoint.data.value}
        </p>
      """

    # Scrape the colour from NV pies
    # TODO: Formally sync colour when nv is stripped out
    colours = {}
    $('.nv-legend-text').each () ->
      colours[$(this).text()] = $(this).prev('circle').css('fill')
    
    randomColor = (i) ->
      colors = d3.scale.category20().range()
      colors[i % colors.length-1]
    
    colourSelector = (server) ->
      if @servers.length > Object.keys(colours).length
        return randomColor(server.id)
      else
        return colours[server.name]
    
    # Create multiple charts, one for each server, to be included using the compose() method
    lines = []
    _.each @servers, (server) ->
      lines.push({
        name: server.name,
        yData: (datapoint) -> datapoint[server.name],
        colour: colourSelector(server)
      })

    # Sum all the servers usages for a given date
    overviewYData = (datapoint) =>
      total = 0
      _.each @servers, (server) ->
        total = total + datapoint[server.name] if _.has(datapoint, server.name)
      total

    graph = new DCGraph(
      selector: '#jg-cpu-usages',
      data: cpuStats,
      statsYData: lines
      overviewYData: overviewYData
      tooltip_function: tooltip
      no_data_html: no_data_html
    )

    graph.statsChart.yAxisLabel('CPU Usage')

    graph.render()

  # Add total to center of pies
  addTotal = (statistic, key, context, showTip = true) ->
    width = $jgChart.width()
    total = context.usage
    unit  = context.unit
    svg = d3.select("#jg-#{key} .jg-chart svg")
    pie = svg.select('g.nv-pieWrap g.nv-pie g g.nv-pie')

    pie.selectAll('g.nv-slice path')
      .on("mouseover", tip.show)
      .on("mouseout", tip.hide)
      .on("click", (d) ->
        url = "#{window.location.protocol}//#{window.location.host}/servers/#{d.data.id}"
        $(window.location).attr('href', url)
      ) if showTip
    pie.append('text')
      .classed({'total-unit': true})
      .attr("dy", ".35em")
      .style("text-anchor", "middle")
      .text("#{total} #{unit}")

    svg.select('g.nv-legendWrap').attr("width", width)

  createPie = (statistic, key, donut = false, context) ->

    nv.addGraph () ->

      svg = d3.select("#jg-#{key} .jg-chart svg")
      svg.call(tip)
      stat = stats.stats[key]

      chart = nv.models.pieChart()
      .x (d) -> return d.name
      .y (d) -> return d.usage
      .donut(donut)
      .showLabels(false)
      .valueFormat(d3.format("0d"))

      _.each statistic, (split) ->
        split.unit = context.unit
        return
      
      if statistic.length == 0
        showTip = false
        totalUsage = {}
        totalUsage[key] = totalUsage['usage'] = stats.stats[key].usage
        totalUsage['name'] = "Total #{key.replace(/_/g, ' ')}"
        svgData = [totalUsage]
      else
        svgData = statistic

      svg.datum(svgData)
      .transition().duration(1200)
      .call(chart)

      nv.utils.windowResize(chart.update)
      addTotal(statistic, key, context, showTip)
      return chart

  addTickets = (ticket) ->
    html =
      """
        <tr>
          <td class="pure-u-1-4">
            <div class='tags #{ticket.status}'>
              #{ticket.status}
            </div>
          </td>
          <td class="pure-u-1-4">
            #{ticket.reference}
          </td>
          <td class="pure-u-1-4">
            <a href="/tickets/#{ticket.id}">#{ticket.subject}</a>
          </td>
          <td class="pure-u-1-4 moment-date">
            #{ticket.updated_at}
          </td>
        </tr>

      """
    $('#jg-tickets tbody').append(html)

  noTickets = ->
    html =
      """
        <tr>
          <td class="pure-u-1 no-data">
            <p>You don't have any tickets</p>
          </td>
        </tr>

      """
    $('#jg-tickets tbody').append(html)


  # Render pies
  keys = ["memory", "disk_size", "cpus", "bandwidth"]

  _.each keys, (key) ->
    split = stats.stats[key].split
    if split.length == 0 && stats.stats[key].usage == 0
      html =
        """
          <div class="no-data">
            <p>You haven't created any servers yet</p>
            <div class="jg-widget-controls"><a href="/servers/create" class="jg-button-lilac jg-new-button">New Server</a></div>
          </div>

        """
      $("#jg-#{key} .jg-chart").html(html)
    else
      createPie(split, key, true, stats.stats[key])

  # Render tickets
  if stats.stats['tickets'].length == 0
    noTickets()
  else
    _.each stats.stats['tickets'], addTickets

  # Render CPU stats
  # Waits for pies to be drawn to get their colours, so they're synced with the graphs
  checkExist = setInterval( () ->
    if $('.nv-legend-text').length
      statsGraph()
      clearInterval(checkExist)
  , 50)

  @momentizeDates()

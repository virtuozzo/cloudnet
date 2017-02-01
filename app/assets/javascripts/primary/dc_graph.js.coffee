# This is a hand-cranked wrapper around some basic DC.js functionality.
# dc.js' annotated example is perhaps the best intro to how it works;
# http://dc-js.github.io/dc.js/docs/stock.html
class @DCGraph
  constructor: (@config) ->
    # The parent CSS selector that forms the base of the stat graph and overview graph
    @selector = @config.selector
    # The data for the graph
    @data = @config.data
    # Data for the main graph's y axis. Must be an Array
    @statsYData = @config.statsYData
    # Data for the overview graph's y axis
    @overviewYData = @config.overviewYData
    # Function to build tooltips
    @tooltip_function = @config.tooltip_function
    # What to display when there isn't any data
    if _.has(@config, 'no+data_html')
      @no_data_html = @config.no_data_html
    else
      @no_data_html =
        """
         <div class="no-data">
           <p>Not enough data is available at the moment</p>
         </div>
        """

    @setup() if @data.length > 0

  setup: () ->
    # Earliest and latest data points
    @startDate = _.min(_.pluck(@data, "date"))
    @endDate = _.max(_.pluck(@data, "date"))

    # Set up crossfilter. See; http://square.github.io/crossfilter/
    @ndx = crossfilter(@data)
    @ndx.groupAll()

    # Uses the D3 Tip library, see; https://github.com/Caged/d3-tip
    @tooltip = d3.tip().attr('class', 'd3-tip').html((d) =>
      '<div class="jg-tooltip-body tooltip-linechart">' + @tooltip_function(d) + '</div>'
    )

    # A dimension is effectivey the x-axis
    @dateDimension = @ndx.dimension (d) -> d.date

    @setupOverviewChart()
    @setupStatsChart()

  # The main big graph
  setupStatsChart: () ->
    @statsChartSelector = "#{@selector} .jg-chart.linechart"

    # Always use a composite chart, even if it only has a single line
    @statsChart = dc.compositeChart(@statsChartSelector)

    lines = []
    @statsYData = [@statsYData] if @statsYData.constructor != Array
    _.each @statsYData, (line) =>
      _.defaults(line, {
        colour: '#428bca',
        name: null
      })
      # Groups are effectively the y-axis
      group = @dateDimension.group().reduceSum line.yData
      lines.push(
        dc.lineChart(@statsChart)
          .group(group, line.name)
          .colors(line.colour)
          # Smoothes the lines a little bit. You can smooth them more but then the tooltips don't
          # match up.
          .interpolate('linear')
      )

    @statsChart
      .height(280)
      # Add all the line graphs
      .compose(lines)
      # The x-axis data
      .dimension(@dateDimension)
      # Connect to the overview graph so that changes on one trigger the other
      .rangeChart(@overviewChart)

  # The cute overview chart underneath the main chart
  setupOverviewChart: () ->
    overviewGroup = @dateDimension.group().reduceSum @overviewYData
    @overviewChart = dc.barChart("#{@selector} .jg-chart.overview-chart")
      .height(60)
      .dimension(@dateDimension)
      .group(overviewGroup)
      # TODO: brushing into a range that has no data in the main graph causes problems
      .x(d3.time.scale().domain([moment(@endDate).subtract(3, 'months'), @endDate]))
      .transitionDuration(500)
      .brushOn(true)
    # remove as much of the y-axis as possible
    @overviewChart.yAxis().ticks(0)
    @overviewChart.yAxisLabel(' ')

  # dc.js' interaction with d3-tip means that unfortunately tooltips need to be re-added after
  # every dc.redraw()
  statsChartTooltips: () ->
    pointSelector = "#{@statsChartSelector} .dot"
    @statsChart.selectAll(pointSelector).call(@tooltip)
    @statsChart
      .selectAll(pointSelector)
      .on('mouseenter', @tooltip.show)
      .on('mouseleave', @tooltip.hide)

  # The main stats line chart
  buildStatsChart: () ->
    @statsChart
      # Attaches an overview chart whose brush redraws this chart
      .rangeChart(@overviewChart)
      # Don't try adjusting this range in order to redraw the chart, it causes errors when the
      # brush tries to filter this chart out of bounds of the domain's range.
      .x(d3.time.scale().domain([@startDate, @endDate]))
      .transitionDuration(500)
      .brushOn(false)
      .renderHorizontalGridLines(true)
      .renderVerticalGridLines(true)
      .elasticY(true)
      .elasticX(true)
      .yAxisPadding('10%')
      # what to do when the chart is redrawn to show a different date range
      .on('filtered', (chart, filter) =>
        $("#{@selector} .jg-widget-controls li").removeClass('current')
        @statsChartTooltips()
      )

    # Only show legend if there is more than 1 line to show
    if @statsYData.length > 1
      @statsChart.legend(dc.legend().x(60).y(10).itemHeight(18).gap(5))

  # 24/7/30 tabs for redrawing the main chart
  activateDateTabs: () ->
    $("#{@selector} .jg-widget-controls li").on('click', (e) =>
      $tab = $(e.currentTarget) # Because the fat arrow overrides `this`
      $("#{@selector} .jg-widget-controls li").removeClass('current')
      # magnificently moment() can handle the english of the tab's text
      parts = $.trim($tab.text()).split(' ')
      distance = parseInt parts[0]
      unit = parts[1]
      range = [moment(@endDate).subtract(distance, unit), @endDate]
      @overviewChart.filterAll() # remove previous filters
      @overviewChart.filter(range) # add the new filter
      @statsChart.redraw()
      @overviewChart.redraw()
      @statsChartTooltips()
      # Add the current class at the end here because the overviewChart's 'filtered' event wipes
      # all the current classes
      $tab.addClass('current')
    )

  render: () ->
    if @data.length == 0
      $("#{@selector} .jg-chart").html(@no_data_html)
    else
      @buildStatsChart()
      @activateDateTabs()
      @statsChart.render()
      @overviewChart.render()
      @overviewChart.filter([moment(@endDate).subtract(24, 'hours'), moment(@endDate)])
      $("#{@selector} .jg-widget-controls li:eq(0)").addClass('current')

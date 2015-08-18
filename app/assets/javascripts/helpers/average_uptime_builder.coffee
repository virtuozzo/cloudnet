class helpers.AverageUptimeBuilder
  constructor: (location) ->
    @data = $.extend({}, location?.uptimes)

  average: (@daysAgo = 30) ->
    return 0 unless (@data and @data.end)
    Math.round(@uptimesSum() / (@daysAgo + 1) * 100) / 100

  uptimesSum: ->
    _(@uptimesTable(@daysAgo)).reduce(
      (m,o) -> m+o.uptime
    ,0)
      
  uptimesTable: ->
    @data.start = @firstDate(@daysAgo)
    new helpers.UptimeGenerator(@data).uptimeInDays()
    
  #starting date from which we calculate average up to '@data.end' date
  firstDate: ->
    moment(@data.end, @dateFormat()).subtract(@daysAgo, 'days')
    
  dateFormat: ->
    "YYYY-MM-DD"
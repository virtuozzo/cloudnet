class helpers.UptimeGenerator

  SEC_IN_DAY = 86400
  
  constructor: (@uptime) ->
    @uptimeTable = []
    
  uptimeInDays: ->
    return null unless @rangeValid()
    @setRange()
    
    @range.by 'day', (m) => 
      @uptimeTable.push @uptimeObjectForDate(m)
    @uptimeTable

  #date as moment object
  uptimeObjectForDate: (date) ->
    return null unless @checkIfDateInRange(date)
    return @buildUptimeObject(date, 0) if _(@uptime.downtimes).isEmpty()
    @buildUptimeObject(date, @getDowntimeForDate(date))
    
  #date as moment object
  buildUptimeObject: (date, downtime) ->
    {
      date: date.toDate()
      uptime: @calculateUptime(downtime)
    }
    
  calculateUptime: (downtime) ->
    Math.round(((SEC_IN_DAY - downtime) / SEC_IN_DAY) * 10000) / 100
    
  #date as moment object
  getDowntimeForDate: (date) ->
    return downtime.downtime for downtime in @uptime.downtimes when moment(downtime.date).isSame(date)
    0
    
  #date as moment object
  checkIfDateInRange: (date) ->
    @range.contains(date)
    
  setRange: ->
    start = moment(@uptime.start, @dateFormat())
    end = moment(@uptime.end, @dateFormat())
    @range = moment.range(start, end)
    
  dateFormat: ->
    "YYYY-MM-DD"
    
  rangeValid: ->
    @uptime and @uptime.start and @uptime.end
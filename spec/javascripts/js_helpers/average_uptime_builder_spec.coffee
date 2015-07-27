describe "AverageUptimeBuilder", ->
  beforeEach ->
    uptimeObject = {
      start: "2015-06-01"
      end: "2015-07-07"
      downtimes: [
        {date: "2015-06-10", downtime: 900},
        {date: "2015-06-15", downtime: 12818},
        {date: "2015-06-16", downtime: 48072}
      ]
    }
    location = {
      uptimes: uptimeObject
    }
    @builder = new helpers.AverageUptimeBuilder(location)
    @builder.daysAgo = 30
    
  it "should have defined getter function", ->
    expect(@builder.average).toBeDefined()
    
  it "should return 0 if no 'end' date", ->
    @builder.data.end = null
    expect(@builder.average(30)).toEqual 0
    
  it "should return 0 if no uptimes data", ->
    @builder.data= null
    expect(@builder.average(30)).toEqual 0
    
  it "#firstDate", ->
    expect(@builder.firstDate().toDate()).toEqual moment("2015-06-07").toDate()
    
  it "should return sum of uptimes", ->
    expect(@builder.uptimesSum()).toEqual 3028.48
    
  it "should return average uptime", ->
    expect(@builder.average()).toEqual 97.69
    expect(@builder.average(15)).toEqual 100
    expect(@builder.average(60)).toEqual 98.83

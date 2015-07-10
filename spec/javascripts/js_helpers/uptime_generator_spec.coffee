describe "UptimeGenerator", ->
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
    @generator = new helpers.UptimeGenerator(uptimeObject)
    start = moment(@generator.uptime.start, @generator.dateFormat())
    end = moment(@generator.uptime.end, @generator.dateFormat())
    @generator.range = moment.range(start, end)
    
  it "should have defined getter function", ->
    expect(@generator.uptime).toBeDefined()
    expect(@generator.uptimeInDays).toBeDefined()

  it "should calculate uptime from downtime sec", ->
    expect(@generator.calculateUptime(100)).toEqual 99.88
    expect(@generator.calculateUptime(0)).toEqual 100
    expect(@generator.calculateUptime(86400)).toEqual 0
    expect(@generator.calculateUptime(43200)).toEqual 50
    expect(@generator.calculateUptime(32570)).toEqual 62.30
    
  describe "#uptimeInDays", ->
    it "should return null if uptime is null", ->
      generator = new helpers.UptimeGenerator(null)
      expect(generator.uptimeInDays()).toBeNull()
      
    it "should return null if no start or end date", ->
      uptimeObject = {
        start: null
        end: "2015-07-07"
      }
      generator = new helpers.UptimeGenerator(uptimeObject)
      expect(generator.uptimeInDays()).toBeNull()
    
      uptimeObject = {
        start: "2015-06-07"
        end: null
      }
      generator = new helpers.UptimeGenerator(uptimeObject)
      expect(generator.uptimeInDays()).toBeNull()
     
    it "should return array of objects", ->
      result = @generator.uptimeInDays()
      expect(result).toEqual(jasmine.any(Array))
      expect(result.length).toEqual 37
    
    it "should return proper uptime values", ->
      result = @generator.uptimeInDays()
      expect(result[0].uptime).toEqual 100
      expect(result[0].date.toString()).toEqual moment("2015-06-01").toDate().toString()
      
      expect(result[9].uptime).toEqual 98.96
      expect(result[14].uptime).toEqual 85.16
      expect(result[15].uptime).toEqual 44.36
      expect(result[16].uptime).toEqual 100
      
  describe "#uptimeObjectForDate", ->
    it "should return null if date out of range", ->
      date = moment("2015-05-07")
      obj = { date: date.toDate(), uptime: 100 }
      expect(@generator.uptimeObjectForDate(date)).toBeNull()
      
    it "should return uptime 100 if no downtimes data", ->
      noDowntimes = {
        start: "2015-06-01"
        end: "2015-07-07"
        downtimes: []
      }
      gen = new helpers.UptimeGenerator(noDowntimes)
      gen.range = moment.range(gen.uptime.start, gen.uptime.end)
      date = moment("2015-06-07")
      obj = { date: date.toDate(), uptime: 100 }
      
      expect(gen.uptimeObjectForDate(date)).toEqual obj
      
    it "should return uptime 100 if there was no downtime at the date in proper range", ->
      date = moment("2015-06-07")
      obj = { date: date.toDate(), uptime: 100 }
      expect(@generator.uptimeObjectForDate(date)).toEqual obj
      
    it "should return calculated uptime if there was a downtime at the date", ->
      date = moment("2015-06-15")
      obj = { date: date.toDate(), uptime: 85.16 }
      expect(@generator.uptimeObjectForDate(date)).toEqual obj

  describe "#buildUptimeObject", ->
    it "should return proper uptime object based on downtime sec", ->
      date = moment("2015-06-07")
      obj = { date: date.toDate(), uptime: 98.96 }
      expect(@generator.buildUptimeObject(date, 900)).toEqual obj
    
    it "should return uptime object with 100% uptime if downtime is null", ->
      date = moment("2015-06-07")
      obj = { date: date.toDate(), uptime: 100 }
      expect(@generator.buildUptimeObject(date, null)).toEqual obj
      
  describe "#getDowntimeForDate", ->
    it "should return 0 if date is not in downtimes", ->
      date = moment("2015-06-07")
      expect(@generator.getDowntimeForDate(date)).toEqual 0
    
    it "should return downtime value if date exists in downtimes", ->
      date = moment("2015-06-15")
      expect(@generator.getDowntimeForDate(date)).toEqual 12818
      
  describe "#checkIfDateInRange", ->
    it "should return true if date is in range", ->
      date = moment("2015-06-07")
      expect(@generator.checkIfDateInRange(date)).toBeTruthy()
      date = moment("2015-06-01")
      expect(@generator.checkIfDateInRange(date)).toBeTruthy()
      date = moment("2015-07-07")
      expect(@generator.checkIfDateInRange(date)).toBeTruthy()
      
    it "should return false if the date is out of range", ->
      date = moment("2014-06-07")
      expect(@generator.checkIfDateInRange(date)).toBeFalsy()
      date = moment("2015-05-31")
      expect(@generator.checkIfDateInRange(date)).toBeFalsy()
      
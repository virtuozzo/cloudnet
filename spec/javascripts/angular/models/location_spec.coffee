describe "Location", ->
  it "should have defined getter functions", ->
    loc=new models.Location
    expect(loc.priceCpu).toBeDefined()
    expect(loc.priceMem).toBeDefined()
    expect(loc.priceDisk).toBeDefined()

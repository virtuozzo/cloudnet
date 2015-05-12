describe "Location", ->
  it "should have defined getter functions", ->
    loc=new models.Location
    expect(loc.fPriceCpu).toBeDefined()
    expect(loc.fPriceMem).toBeDefined()
    expect(loc.fPriceDisk).toBeDefined()

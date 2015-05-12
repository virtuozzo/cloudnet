describe "GeoJsonBuilder", ->
  it "should have defined getter functions", ->
    builder = new helpers.GeoJsonBuilder
    expect(builder.generate).toBeDefined()


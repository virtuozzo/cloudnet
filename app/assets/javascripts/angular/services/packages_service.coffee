@app.service "Packages", ['ServerSearchState',
  class Packages
    activePackage: undefined
    packages: []
    
    constructor: (@state) ->
      @packages = _(models.packagesData).map (pack) -> new models.Package(pack)

    checkIfPackageSet: ->
      data = @state.getIntegerCounts()
      @activePackage = _(@packages).find (pack) ->
        _.isEqual(pack.getData(), data)
      @setPackageFilter()
    
    activatePackage: (packId) ->
      @activePackage = _(@packages).find (pack) -> pack.id is packId
      @setPackageFilter()
      
    setPackageFilter: ->
      @state.packageFilter = {}
      @state.packageFilter = {budgetVps: false} unless @activePackage
]
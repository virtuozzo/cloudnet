class models.Package
  constructor: (pack) ->
    $.extend @, pack
    
  getData: ->
    cpu:  @cpu
    disk: @disk
    mem:  @mem
    
  
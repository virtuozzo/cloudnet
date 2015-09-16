class models.Location
  constructor: (options) ->
    $.extend @, options
    @getPopupPictures()
    
  getPopupPictures: ->
    photoBuilder = new helpers.PhotoBuilder(this)
    @photoData = photoBuilder.fetchPhoto()
    @photoData.then (photo) =>
      @photoData = photo
      
  pricePerHour: (counts) ->
    exactPricePerHour.call(@, counts.cpu, counts.mem, counts.disk).toFixed(5) 
    
  pricePerMonth: (counts) ->
    (exactPricePerHour.call(@, counts.cpu, counts.mem, counts.disk) * 672).toFixed(2)

  fPriceCpu: ->
    parseFloat(@priceCpu)
    
  fPriceMem: ->
    parseFloat(@priceMemory)
    
  fPriceDisk: ->
    parseFloat(@priceDisk)
    
  freeBandwidth: (counts) ->
    (parseFloat(@inclusiveBandwidth) / 1024 * counts.mem).toFixed(1)
    
  exactPricePerHour = (cpu, mem, disk) ->
    cpu = parseInt(cpu,10)
    mem = parseInt(mem,10)
    disk = parseInt(disk,10)
    (cpu * @fPriceCpu() + 
     mem * @fPriceMem() + 
     disk * @fPriceDisk()) / 100000
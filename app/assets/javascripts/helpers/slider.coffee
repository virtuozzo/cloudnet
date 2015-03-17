class helpers.Slider
  constructor: (@scope, @$sliderObject, @ctrl, @state, @packages) ->
    @attributes = @setDefaultAttributes()
    @initializeSlider()
  
  initializeSlider: ->
    @setSliderInitialAtributes()
    @attachSliderToModelChange()
    @updateModelWhenSLiderChange()
    @enableDisableSliders()

  setSliderInitialAtributes: ->
    @$sliderObject.noUiSlider @attributes
    
  attachSliderToModelChange: ->
    @ctrl.$render = => 
      @setValue(@ctrl.$viewValue)
      @ctrl.$setViewValue(@getValue())
      @packages.checkIfPackageSet()
    
  updateModelWhenSLiderChange: ->
    @$sliderObject.on 'slide', =>
      @scope.$apply(
        @ctrl.$setViewValue(@getValue())
        @packages.checkIfPackageSet()
      )
      
  enableDisableSliders: ->
    switch @scope.enable
      when true then @enableSlider()
      when false then @disableSlider()
      else @watchStateForEnable()

  watchStateForEnable: ->
    @scope.$watch =>
      @state.slidersEnabled
    , (newV) =>
      if newV then @enableSlider() else @disableSlider()
      
  disableSlider: ->
    @$sliderObject.attr('disabled', 'disabled')
 
  enableSlider: ->
    @$sliderObject.removeAttr('disabled')
    
  setValue: (n) ->
    @$sliderObject.val(n)

  getValue: ->
    @$sliderObject.val()
    
  setDefaultAttributes: ->
    switch @scope.defaults
      when 'cpu' then @cpuDefaults()
      when 'mem' then @memDefaults()
      when 'disk' then @diskDefaults()
      when 'index' then @indexDefaults()
      else @defaultAtt()
        
  defaultAtt: ->
    start: 1
    step:  1
    mode: 'range'
    density: 1
    behaviour: 'tap'
    range:
      min: 1
      max: 4
    connect: "lower"
    serialization:
      format:
        decimals: 0
      
  cpuDefaults: ->
    @defaultAtt()
    
  memDefaults: ->
    _(@defaultAtt()).extend
      start: 128
      step: 128
      range:
          min: 128
          max: 7680
          
  diskDefaults: ->
    _(@defaultAtt()).extend
      start: 10
      step: 10
      range:
        min: 10
        max: 100
  
  indexDefaults: ->
    _(@defaultAtt()).extend
      start: 0
      step: 1
      range:
        min: 0
        max: 100
@app.directive "sliderWidget", ['ServerSearchState', 'Packages', (State, Packages) ->
  scope: 
    enable: '='
    defaults: '@'
  require: 'ngModel'
  link: ($scope, $element, $attr, ngModelCtrl) ->
    new helpers.Slider($scope, $($element), ngModelCtrl, State, Packages)
]
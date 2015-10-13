# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@app.factory "ServerIps", ["$resource", ($resource) ->
  $resource "/servers/:serverId/ip_addresses.json", {}, {
    'get': {method: 'get', isArray: true}
  }
]

@app.controller "ServerIpsCtrl", ["$scope", "$timeout", "ServerIps", ($scope, $timeout, ServerIps) ->
  tick = (serverId) ->      
    ServerIps.get {serverId: serverId}, (response) ->
      $scope.ips = response
      $scope.numberOfPages  = ->
        Math.ceil $scope.ips.length / $scope.pageSize
      $scope.addedNewIp = ->
        ($scope.ips.length > $scope.originalIpsCount) ? true : false

      $timeout (() -> tick(serverId)), 10 * 1000

  $scope.init = (serverId) ->
    tick(serverId)
    $scope.currentPage      = 0;
    $scope.pageSize         = 10;
    $scope.originalIpsCount = 1;

  return
]

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@app.factory "Servers", ["$resource", ($resource) ->
  $resource "/servers/:serverId.json", {serverId: "@id"}
]

@app.factory "ServerIps", ["$resource", ($resource) ->
  $resource "/servers/:serverId/ip_addresses.json", {}, {
    'get': {method: 'get', isArray: true}
  }
]

@app.controller "ServerIpsCtrl", ["$scope", "$timeout", "Servers", "ServerIps", ($scope, $timeout, Servers, ServerIps) ->
  tick = (serverId) ->
    Servers.get {serverId: serverId}, (response) ->
      $scope.server = response
    
    ServerIps.get {serverId: serverId}, (response) ->
      $scope.ips = response
      $scope.numberOfPages  = ->
        Math.ceil $scope.ips.length / $scope.pageSize
      $scope.addedNewIp = ->
        ($scope.ips.length > $scope.originalIpsCount) ? true : false

      $timeout (() -> tick(serverId)), 10 * 1000
      
  $scope.disabled = (server) ->
    server.state != 'on' && server.state != 'off'
  
  $scope.ips_disabled = (server) ->
    server.ips_available == false

  $scope.init = (serverId) ->
    tick(serverId)
    $scope.currentPage      = 0;
    $scope.pageSize         = 10;
    $scope.originalIpsCount = document.getElementById('initial_ips_count').value;

  return
]

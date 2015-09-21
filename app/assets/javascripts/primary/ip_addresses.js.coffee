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

      $timeout (() -> tick(serverId)), 10 * 1000

  $scope.disabled = (server) ->
    server.state != 'on' && server.state != 'off'    

  $scope.init = (serverId) ->
    tick(serverId)
    $scope.currentPage    = 0;
    $scope.pageSize       = 10;

  return
]

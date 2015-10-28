# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@app.factory "Servers", ["$resource", ($resource) ->
  $resource "/servers/:serverId.json", {serverId: "@id"}
]

@app.factory "ServerBackups", ["$resource", ($resource) ->
  $resource "/servers/:serverId/backups.json", {}, {
    'get': {method: 'get', isArray: true}
  }
]

@app.controller "ServerBackupsCtrl", ["$scope", "$timeout", "Servers", "ServerBackups", ($scope, $timeout, Servers, ServerBackups) ->
  tick = (serverId) ->
    Servers.get {serverId: serverId}, (response) ->
      $scope.server = response
    
    ServerBackups.get {serverId: serverId}, (response) ->
      $scope.backups = response
      $scope.numberOfPages  = ->
        Math.ceil $scope.backups.length / $scope.pageSize
      $scope.addedNewBackup = ->
        ($scope.backups.length > $scope.originalBackupsCount) ? true : false
      
      $scope.unbuiltBackups = 0
      angular.forEach $scope.backups, (backup) ->
        $scope.unbuiltBackups++ if backup.built == false

      $timeout (() -> tick(serverId)), 10 * 1000
      
  $scope.disabled = (server) ->
    (server.state != 'on' && server.state != 'off') || $scope.unbuiltBackups > 0
  
  $scope.momentizedDate = (momentDate) ->
    format = "YYYY-MM-DDTHH:mm:ssZ"
    moment(momentDate, format).fromNow()

  $scope.init = (serverId) ->
    tick(serverId)
    $scope.currentPage      = 0;
    $scope.pageSize         = 10;
    $scope.originalBackupsCount = document.getElementById('initial_backups_count').value;

  return
]

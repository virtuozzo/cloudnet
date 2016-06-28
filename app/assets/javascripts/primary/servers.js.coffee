# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@app.factory "Servers", ["$resource", ($resource) ->
  $resource "/servers/:serverId.json", {serverId: "@id"}
]
    
@app.controller "ServersCtrl", ["$scope", "$timeout", "Servers", ($scope, $timeout, Servers) ->
  tick = ->
    Servers.query (response) ->
      $scope.servers = response
      $scope.numberOfPages  = ->
        Math.ceil $scope.servers.length / $scope.pageSize

      $timeout tick, 10 * 1000

  $scope.disabled = (server) ->
    server.state != 'on' && server.state != 'off'    

  tick()
  $scope.currentPage    = 0;
  $scope.pageSize       = 10;

  return
]

@app.factory "ServerEvents", ["$resource", ($resource) ->
  $resource "/servers/:serverId/events.json", {}, {
    'get': {method: 'get', isArray: true}
  }
]

@app.controller "ServerIndividualCtrl", ["$scope", "$timeout", "Servers", "ServerEvents", ($scope, $timeout, Servers, ServerEvents) ->
  tick = (serverId) ->
    Servers.get {serverId: serverId}, (response) ->
      $scope.server = response

    ServerEvents.get serverId: serverId, (response) ->
      $scope.events = response
      $scope.numberOfPages  = ->
        Math.ceil $scope.events.length / $scope.pageSize

    $timeout (() -> tick(serverId)), 10 * 1000

  $scope.disabled = (server) ->
    server.state != 'on' && server.state != 'off' && server.state != 'blocked'

  $scope.init = (serverId) ->
    tick(serverId)
    $scope.currentPage    = 0;
    $scope.pageSize       = 10;

  return
]

$ ->
  input_element = $("#destroy_server_input")
  button = $("#destroy_server_button")
  expected_input = input_element.data("expected")

  input_element.on "keyup", (e) ->
    value = input_element.val()
    if value && value.toLowerCase() == expected_input.toLowerCase()
      button.removeAttr('disabled');
    else
      button.attr('disabled','disabled');
  
  $(document).on "click", "#install-notes-button", (e) ->
    e.preventDefault()
    serverId = $(this).attr('server-id')
    loadInstallNotes(serverId)

  loadInstallNotes = (serverId) ->    
    $('#install-notes').on 'show.bs.modal', (e) -> 
      $("#install-notes .modal-body").html """
        <div class="jg-widget-form pure-g-r clearfix">
          <div>
            <p>
              Please wait, getting install notes...
            </p>
          </div>
        </div>
      """
    
    $("#install-notes").modal("show")
      
    $.ajax 
      type: "GET",
      url: "/servers/#{serverId}/install_notes",
      dataType: "html",
      success: (response) ->
        $("#install-notes .modal-body").html(response)

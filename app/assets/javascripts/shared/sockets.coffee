class @Sockets
#elementary implementation
  constructor: ->
    @socket = @createSocket()
    
  updateUnbilledRevenue: (el) ->
    @sendMessage("getUnbilledRevenue")
    
    @socket.onmessage = (e) ->
      if e.data
        el.text(e.data)
        
  checkSocket: ->
    @socket = @socket || @createSocket()
    
  createSocket: (path) ->
    new WebSocket("ws://#{window.location.host}/sockets/event")
    
  sendMessage: (m) ->
    s = @socket
    if @socketOpen()
      s.send(m)
    else
      s.onopen = -> s.send(m)
        
  socketOpen: ->
     @socket.readyState == @socket.OPEN
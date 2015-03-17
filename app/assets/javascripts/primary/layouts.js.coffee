scope      = @
@jgLayouts = {}

# Generic Ractive layouts

$ ->
  Notifications = Ractive.extend(
    template: '#notification_template'
    
    init: (options) ->
      scope = @
      data =
        notifications: {}

      data = $.extend {}, data, options.data



      @on
        begin: (event, cb) ->
          cb?(event)

        new_notification: (error, message, messages, cb) ->
          
          notifications =
            error:    if error is 'error' then true else false
            message:  message.charAt(0).toUpperCase() + message.slice(1)
            messages: messages
            event:
              date: new Date()
              type: error

          console.log notifications

          @set 'notifications', notifications

          if options?.showOnSet is true then @show()


          cb?(notifications)
          
      @hide = -> @set 'notification.visible', false
      @show = -> @set 'notifications.visible', true

      @fire 'begin', {message: 'begin jg-notifications', type: 'begin', time: new Date()}
          
      return
  )

  scope.jgLayouts.Notifications = Notifications

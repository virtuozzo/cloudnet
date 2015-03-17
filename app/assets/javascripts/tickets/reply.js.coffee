$ ->

  add_reply_error = new window.jgLayouts.Notifications
    el:         '#add_reply_error'
    template:   '#notification_template'
    showOnSet:  true

  lastUpdate      = _.last ticket_replies
  lastTimeStamp   = new Date(lastUpdate?.updated_at)
  console.log _.size ticket_replies
  older = 
    visible:  true
    total: -> return _.size ticket_replies
    length: -> return @total() - 1

  pendingNewerRequest = false

  runOnComplete = ->
    $('.moment-date:not(.momentized)').each ->
        format = "YYYY-MM-DD HH:mm:ss ZZ"
        $(this).text(moment($(this).text(), format).fromNow())
        $(this).addClass('momentized')
    prettyPrint();

  TicketReplyList = Ractive.extend(
    template: '#reply_template'
    init: (options) ->
      self = this

      interval = options.pollInterval || 5000

      @older = 
        visible:      options?.show_older?.visible || true
        total:      options?.show_older?.total || 0
        hidden:     options?.show_older?.hiddenItems || 0
        el:         options.show_older.el
        min:        options?.show_older?.min || 5
        showLast:       2
        actualHidden: -> return (@total() - @showLast) + 1

      @data =
        errorMessage: 'POO'
     

      @show = ->

        if @older.total() >= @older.min

          $(@older.el).slice(0, @older.actualHidden()).css
            display: 'inline-block'
            opacity: 100

          $(@older.el).eq(@older.actualHidden()).removeClass('initial_ticket')


      @hide = ->
        if @older.total() >= @older.min
          $(@older.el).slice(0, @older.actualHidden()).css
            display: 'none'
            opacity:  0

          $(@older.el).eq(@older.actualHidden()).addClass('initial_ticket')

      if interval
        intervalId = setInterval(->
            self.fire 'fetch'
            return
          , interval)

      @on
        begin: (event, cb) ->
          cb?()

        teardown: ->
          clearInterval intervalId

        new_reply: (reply, cb) ->
          event = {type: 'new Reply', time: new Date(), data: reply}
          ticket_replies.push reply
          cb?(event)
          return


      @fire 'begin', {message: 'begin list', type: 'begin', time: new Date()}
          

      return
  )

  fetchResults = (url) ->
    deferred = Q.defer()
    
    if pendingNewerRequest is true then return

    pendingNewerRequest = true

    $.ajax 
      url: url
      dataType: 'json'

      error: (xhr, status, error) ->
        pendingNewerRequest = false
        deferred.reject(xhr, status, error)

      success: (data, xhr, status) ->
        pendingNewerRequest = false
        deferred.resolve(data, xhr, status)

  replies = new TicketReplyList
    el: '#jg-show-ticket'
    template: '#reply_template'
    data:
      original:     ticket
      replies:      ticket_replies
      older:        older

    show_older:
      total:          ->  return _.size ticket_replies
      hiddenItems:        5
      el:             '#jg-ticket-thread li'

    
    append: true

    complete: -> 
      @hide()
      runOnComplete()

  replies.on
    fetch: ->
      self = @
      fetchResults("/tickets/#{ticket.id}.json").then((data, xhr, status) ->
        ticket     = data

        newReplies = data['replies']
        self.set 'original', ticket
        results = _.reject newReplies, (reply) -> _.where(ticket_replies, {id: reply.id}).length != 0

        if results.length is 1
          _.each results, (result) ->
            if result.staff_reply is yes then result.new = true
            ticket_replies.push result

        

      ).fail((xhr, status, error) ->
        handleError('Fetch for new replies has failed.')
      )


    change: (data) ->
      if data.original?
        if data.original.status in ['closed', 'solved']
          @fire 'teardown'
      runOnComplete()

    show_older: (e) ->
      @set 'older.visible', false
      @show()

    show_less: (e) ->
      @set 'older.visible', true
      @hide()


  $("#new_ticket_reply").on("ajax:success", (e, data, status, xhr) ->
    window.cmEditor.clearContent() if window.cmEditor
    
    reply = data
    add_reply_error.fire 'new_notification', status, status, []
    if reply
      replies.fire 'new_reply', reply, (event) ->
        runOnComplete()
  ).on "ajax:error", (e, xhr, status, error) ->
    errors = _.parseErrors xhr.responseJSON.errors

    add_reply_error.fire 'new_notification', status, error, [errors]
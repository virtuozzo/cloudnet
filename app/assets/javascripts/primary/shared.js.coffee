scope = @

_.mixin parseErrors: (errors) ->
  error = []
  _.each errors, (v, k) ->
    error.push(k.substr(0, 1).toUpperCase() + k.substr(1) + " " + v.join(', '))
  return error.join(', ')

_.mixin select2Array: (data, fields, options) ->
    i = 0

    key = options?.key || 'integer'

    collection = _.map data, (value, index) ->
      data = _.pick value, fields
      data['id'] = switch key
        when true then index
        when 'integer' then i
        else value[key]
      
      i++
      return data
    return collection

_.mixin simplePluralize: (word, number = 2) ->
  switch number
    when 1 then word
    else word + 's'
      
waitForFinalEvent = (->
  timers = {}
  (callback, ms, uniqueId, fired) ->
    uniqueId = "Don't call this twice without a uniqueId"  unless uniqueId
    clearTimeout timers[uniqueId]  if timers[uniqueId]
    timers[uniqueId] = setTimeout(callback, ms)
    return
)()

$ ->
  $('.bs-tooltip').tooltip
      animation:  true

  toolbar = [
    {name: 'bold', action: Editor.toggleBold},
    {name: 'italic', action: Editor.toggleItalic},
    '|',

    {name: 'quote', action: Editor.toggleBlockquote},
    {name: 'unordered-list', action: Editor.toggleUnOrderedList},
    '|',

    {name: 'link', action: Editor.drawLink},
    {name: 'code', action: Editor.toggleCode}
    '|',

    {name: 'info', action: 'https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet'},
    {name: 'preview', action: Editor.togglePreview},
    {name: 'fullscreen', action: Editor.toggleFullScreen}
  ];
  
  editor_element = document.getElementById("editor")

  if editor_element
    editor = new Editor
      element: editor_element
      toolbar: toolbar
    editor.render()

    scope.cmEditor = editor

  $(window).resize (e) ->
    $('.jg-widget-content .jg-chart').addClass('hide-chart')

    waitForFinalEvent (->
      $('.jg-widget-content .jg-chart').removeClass('hide-chart')
      return
    ), 300, "finalResize", moment().format()

  $('body .scrollable').perfectScrollbar
    wheelSpeed: 30
    wheelPropagation: false

  @momentizeDates = ->
    $('.moment-date:not(.momentized)').each ->
      format = "YYYY-MM-DDTHH:mm:ssZ"
      $(this).text(moment($(this).text(), format).fromNow())
      $(this).addClass('momentized')

  @momentizeDates()

  @hideText = ->
    $('.text-content').each ->
      $el = $(this)
      contentLength = $el.find('p').text().length

      if contentLength > 300
        $el.addClass('show-less')
      else
        $el.next('a.show-more-or-less').hide()


    $('a.show-more-or-less').click ->
      $(this).toggleClass('less')
      $(this).prev('.text-content').toggleClass('show-more show-less')

  @hideText()

  removeErrorClass = -> $(@).removeClass('field_with_errors')

  jgSelect2Defaults = 
    dropdownCssClass:   'jg-dropdown'
    containerCssClass:  'jg-select'

  _.extend $.fn.select2.defaults, jgSelect2Defaults

  $('select, input#select_2').each (index) ->
    $(@).select2()

  $('body .field_with_errors').each ->
    $this = $(@)
    $this.find('input, select, textarea').on 'click', removeErrorClass.bind(@)

  toggleAccordion = ($target) ->
    $target.parent().parent().toggleClass('open')
    $target.toggleClass('icon-arrow-down').toggleClass('icon-arrow-up active')
  $('ul.jg-step-box li .step-header #toggle').on 'click', (e) -> unless $(this).parent().parent().hasClass('disabled') then toggleAccordion($(this))

  # Run Code highlighting
  prettyPrint();


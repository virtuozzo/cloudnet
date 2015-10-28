# Include this wherever you want to use the up/down toggle view

$ ->
  
  toggleClass = ($el, clazzName) ->
    flagButton = $el.hasClass(clazzName)
    $el[{true: 'removeClass', false: 'addClass'}[flagButton]](clazzName)
    return flagButton
      
  toggleInfo = ($el) ->
    $parent = $el.parent()
    activeClass = toggleClass($parent, 'open')
    $parent.find('.jg-disclosure').toggleClass('icon-arrow-down icon-arrow-up active')
    $tgbl = $parent.find('.jg-toggleable')
    if activeClass is false
      $tgbl.css
        display: 'inline-block'
      .animo( { animation: 'fadeInDown', duration: 0.2 })
    else
      $tgbl.animo( { animation: 'fadeOutUp', duration: 0.2, keep: true}, ->
        $tgbl.css
          display: 'none'
      )
      
    return
    
  $('.jg-toggle').click (e) ->
    toggleInfo $(@)
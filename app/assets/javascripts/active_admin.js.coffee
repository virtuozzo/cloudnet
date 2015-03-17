#= require active_admin/base
$ ->
  $('form').on 'focus', 'input[type=number]', (e) ->
    $(this).on 'mousewheel.disableScroll', (e) -> 
      e.preventDefault()
  
  $('form').on 'blur', 'input[type=number]', (e) -> 
    $(this).off('mousewheel.disableScroll')
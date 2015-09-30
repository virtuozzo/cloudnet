#= require active_admin/base
#= require shared/sockets
#= require shared/page
$ ->
  $('form').on 'focus', 'input[type=number]', (e) ->
    $(this).on 'mousewheel.disableScroll', (e) -> 
      e.preventDefault()
  
  $('form').on 'blur', 'input[type=number]', (e) -> 
    $(this).off('mousewheel.disableScroll')
  
  if PageIs.adminDashboard()
    serverData = new Sockets
    serverData.updateUnbilledRevenue($('#unbilled_revenue')) 

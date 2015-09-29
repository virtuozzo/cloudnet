class @PageIs
  
  @adminDashboard: ->
    @action('admin_dashboard') && @action('active_admin')
  
    
  @action: (controller, action=null) ->
    if action
      $('body').hasClass([controller, action].join('-'))
    else
      $('body').hasClass(controller)
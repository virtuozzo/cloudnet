class @PageIs

  @adminDashboard: ->
    @action('admin_dashboard') && @action('active_admin')

  @adminBuildChecker: ->
    @action('active_admin') && @action('admin_build_checkers')

  @action: (controller, action=null) ->
    if action
      $('body').hasClass([controller, action].join('-'))
    else
      $('body').hasClass(controller)
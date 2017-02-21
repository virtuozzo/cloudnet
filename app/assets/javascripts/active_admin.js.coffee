#= require active_admin/base
#= require shared/sockets
#= require shared/page
#= require build_checker/build_checker_configuration

$ ->
  $('form').on 'focus', 'input[type=number]', (e) ->
    $(this).on 'mousewheel.disableScroll', (e) ->
      e.preventDefault()

  $('form').on 'blur', 'input[type=number]', (e) ->
    $(this).off('mousewheel.disableScroll')

  if PageIs.adminBuildChecker()
    $('input[name=concurrentBuilds]').on 'input', ->
      $('#concurrentBuildsValue').text(this.value)
    $('input[name=concurrentBuilds]').mouseup ->
      newValue = document.querySelector('input[name=concurrentBuilds]').value
      BuildCheckerConfiguration.concurrentBuilds(newValue)

    $('input[name=queueSize]').on 'input', ->
      $('#queueSizeValue').text(this.value)
    $('input[name=queueSize]').mouseup ->
      newValue = document.querySelector('input[name=queueSize]').value
      BuildCheckerConfiguration.queueSize(newValue)

    $('input[name=sameTemplate]').on 'input', ->
      $('#sameTemplateValue').text(this.value)
    $('input[name=sameTemplate]').mouseup ->
      newValue = document.querySelector('input[name=sameTemplate]').value
      BuildCheckerConfiguration.sameTemplateGap(newValue)

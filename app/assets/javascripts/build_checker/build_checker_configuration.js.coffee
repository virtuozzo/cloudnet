class @BuildCheckerConfiguration
  @concurrentBuilds: (value) ->
    $.post 'build_checkers/concurrent_builds',  {value: value}
      .done (result) ->
        document.querySelector('input[name=serverConcurrentBuilds]').value = result.serverValue
      .fail (result) ->
        serverValue = document.querySelector('input[name=serverConcurrentBuilds]').value
        document.querySelector('input[name=concurrentBuilds]').value = serverValue
        document.getElementById('concurrentBuildsValue').innerText = serverValue
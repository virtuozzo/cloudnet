$ ->
  $("#jg-payg-widget").on 'payg-topup-complete', (event) ->
    urlPayg = if (serverId?) then "/servers/#{serverId}/create/payg" else "/servers/create/payg"
    $.ajax 
      type: "GET",
      url: urlPayg,
      dataType: "html",
      success: (response) ->
        $("#jg-payg-widget").html(response)
  return
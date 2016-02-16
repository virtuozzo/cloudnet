$ ->
  $("#jg-payg-widget").on 'payg-topup-complete', (e) ->
    $.ajax 
      type: "GET",
      url: "/billing/payg",
      dataType: "html",
      success: (response) ->
        $("#jg-payg-widget").html(response)
  
  $('#auto_topup').on 'change', (e) ->
    $(this).closest("form").submit()

  return

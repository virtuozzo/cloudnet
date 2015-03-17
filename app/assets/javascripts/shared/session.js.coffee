$ ->
  $('input.form-control').each ->
    $(this).focus ->
      $(this).parent().parent().addClass('active')
    $(this).focusout ->
      $(this).parent().parent().removeClass('active')
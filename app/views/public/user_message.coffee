$('#message-sent').addClass('show-mes').removeClass('hide-mes')
$('#message-sent-form')[0].reset()
setTimeout ->
  $('#message-sent').addClass('hide-mes').removeClass('show-mes')
, 5000
$ ->
  coupon_code_field = $('#coupon_code')
  coupon_submit_button = $('#coupon_code_submit')

  $(coupon_submit_button).on 'click', (e) ->
    e.preventDefault()

    $(coupon_submit_button).text("Please wait, verifying coupon code...")
    $(coupon_submit_button).attr('disabled', 'disabled')

    $.ajax 
      type: "POST",
      data: { coupon_code: $(coupon_code_field).val() },
      url: '/billing/set_coupon_code',
      dataType: "html",
      success: (response) ->
        $('#jg-coupon-form').html(response)
        $('#jg-coupon-form').trigger('coupon-code-added')
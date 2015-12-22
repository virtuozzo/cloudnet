$ ->
  $(document).on "click", "#payg-top-up-card", (e) ->
    amount = $('#payg_amount').val()

    $('#payg-confirm-payg-dialog').on 'show.bs.modal', (e) -> 
      $("#payg-confirm-payg-dialog #confirm-payg-content").html """
        <div class="jg-widget-form pure-g-r clearfix">
          <div>
            <p>
              Please wait, loading payment confirmation...
            </p>
          </div>
        </div>
      """

      $.ajax 
        type: "GET",
        url: "/payg/confirm_card_payment?amount=#{amount}",
        dataType: "html",
        success: (response) ->
          $("#payg-confirm-payg-dialog #confirm-payg-content").html(response)
          addHandlerForPaymentConfirmation(amount)

    $('#payg-add-funds').modal('hide')
    $("#payg-confirm-payg-dialog").modal('show')

  addHandlerForPaymentConfirmation = (amount) ->
    confirm_payment_button = '#payg_card_confirm_payment'

    $(confirm_payment_button).on 'click', (e) ->
      $(confirm_payment_button).text("Please wait, verifying payment...")
      $(confirm_payment_button).attr('disabled', 'disabled')

      $.ajax 
        type: "POST",
        url: "/payg/card_payment?amount=#{amount}",
        dataType: "html",
        success: (response) ->
          $("#payg-confirm-payg-dialog #confirm-payg-content").html(response)
          $('#jg-payg-widget').trigger('payg-topup-complete')

  $(document).on "click", "#payg_paypal_button", (e) ->
    amount = $('#payg_amount').val()
    link_with_amount = $(this).attr('href') + "?amount=#{amount}"
    $(this).attr('href', link_with_amount)
    $('#payg-add-funds').modal('hide')

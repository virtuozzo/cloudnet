@pp_responder =
  cancelHandler: ->
    $('#payg-status-payg-dialog').on 'show.bs.modal', (e) -> 
      $("#payg-status-payg-dialog #status-payg-content").html """
        <div class="jg-widget-form pure-g-r clearfix">
          <div>
            <p>Sorry, we could not complete the transaction with Paypal. Please try again later</p>
          </div>
        </div>
      """

    $("#payg-status-payg-dialog").modal('show')

  successHandler: (successHTML) ->
    $('#payg-status-payg-dialog').on 'show.bs.modal', (e) -> 
      $("#payg-status-payg-dialog #status-payg-content").html successHTML
    $("#payg-status-payg-dialog").modal('show')
    
    $("#jg-payg-widget").trigger $.Event("payg-topup-complete", {})
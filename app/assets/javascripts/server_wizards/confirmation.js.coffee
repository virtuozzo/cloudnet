generate_card_html = ->
  return if account_cards.length <= 0

  card_output = ""
  _.each account_cards, (card) ->
    if card.primary is true
      check_primary = "checked"
      primary = """
        <div class="pure-u-1-6">
          <span class="tags primary">Primary Card</span>
        </div>
      """
    else
      primary = ""
      check_primary = ""

    card_output += 
      """
        <tr class="selectable" data-id="#{card.id}" data-validation="#{card.requires_validation}">
          <td>
            <input id="server_wizard_card_id_#{card.id}" name="server_wizard[card_id]" type="radio" value="#{card.id}" #{check_primary}>
          </td>
          <td>
            <div class="pure-g">
              <div class="pure-u-1-6">
                <div class="cardtype icon-#{card.card_type.replace(' ', '-')}"></div>
              </div>
              <div class="pure-u-2-3">
                **** **** **** #{card.last4}
                &nbsp;
                <i class="jg-icon icon-key #{if card.requires_validation then "" else "hide"}" 
                  data-toggle="tooltip" data-placement="top" 
                  title="Servers created on this card require admin validation"></i>
              </div>

              #{primary}
            </div>
          </td>
          <td>#{card.expiry_month} / #{card.expiry_year}</td>
        </tr>
      """

  return card_output


$ ->
  card_table    = "#card-table"
  card_form     = "#jg-card-form"
  payment_type  = "#server_wizard_payment_type"

  enableWizardConfirmTabs = ->
    $('#jg-tabs li a').on 'click', (e) ->
      e.preventDefault()

      allDivs = _.map $('#jg-tabs li a'), (el) -> $(el).attr('href')
      $('#jg-tabs li').removeClass 'active'
      _.each allDivs, (el) -> $(el).hide()

      activeTab = $(this).attr('href')
      $(this).parent().addClass 'active'
      chooseActiveTab(activeTab)
      $(activeTab).show()

    if $(payment_type).val() == 'payg'
      $('#jg-tabs li:nth-child(2) a').click()
    else
      $('#jg-tabs li:first a').click()

  chooseActiveTab = (tab) ->
    if tab == "#step-wizard-payg"
      $(payment_type).val('payg')
    else
      $(payment_type).val('prepaid')

  enableWizardConfirmTabs()

  renderCards = ->
    $(card_table).html(generate_card_html())
    $(card_table).find('i').tooltip()
    bindClickEvents()

  bindClickEvents = ->
    $("#{card_table} tr").click ->
      $(this).find('input[type=radio]').prop('checked', true);
      $("#{card_table} tr.selected").removeClass('selected')
      $(this).addClass('selected')

      if $(this).data('validation') == "1" || $(this).data('validation') == 1
        showValidateWarningMessage()
        disableCreateServerButton()
      else
        hideValidateWarningMessage()

    hideValidateWarningMessage()

  validate_warning_box = "#cc_card_validate_warning"
  validate_check_box   = "create_server_confirm_validate"
  create_prepaid_server_button = "#jg-prepaid-create-server"
  create_payg_server_button = "#jg-payg-create-server"

  showValidateWarningMessage = ->
    message = """
      <strong>The card you have selected requires admin validation. </strong>
      Any servers created using this card will be placed in a queue for 
      admin approval before the server is created. Please check the box to
      confirm that you understand and would like to proceed
      """
    $(validate_warning_box).html """
      <div class='alert alert-warning'>
        <div class="pure-g">
          <div class="pure-u-1-24 checkbox">
            <input class="form-control" id="#{validate_check_box}" type="checkbox">
          </div>
          <div class="pure-u-23-24"><label for="#{validate_check_box}" class="jg-card-validate">#{message}</label></div>
        </div>
      </div>
      """
    $("##{validate_check_box}").change (e) ->
      if $(this).is(':checked')
        enableCreateServerButton()
      else 
        disableCreateServerButton()

  hideValidateWarningMessage = ->
    $(validate_warning_box).html ""
    enableCreateServerButton()

  disableCreateServerButton = ->
    $(create_prepaid_server_button).attr('disabled', 'disabled')
    $(create_payg_server_button).attr('disabled', 'disabled')

  enableCreateServerButton = ->
    $(create_prepaid_server_button).removeAttr('disabled')
    $(create_payg_server_button).removeAttr('disabled')

  $(card_form).on 'add_card', (e) ->
    renderCards()

  renderCards()

  server_wizard_next_step_button = "#server_wizard_next_step"
  $("#new_server_wizard").submit (event) ->
    _.each $('#jg-card-form').find('input'), (input) ->
      $(input).val("")

    $(server_wizard_next_step_button).text("Please wait...")
    $(server_wizard_next_step_button).attr('disabled', 'disabled')

    return

  $('#jg-coupon-form').on 'coupon-code-added', (event) ->
    $.ajax 
      type: "GET",
      url: '/servers/create/prepaid_server_cost',
      dataType: "html",
      success: (response) ->
        $('#jg-confirmation-costs').html(response)

    $.ajax 
      type: "GET",
      url: '/servers/create/payg_server_cost',
      dataType: "html",
      success: (response) ->
        $('#jg-payg-confirmation-costs').html(response)

  $("#jg-payg-widget").on 'payg-topup-complete', (event) ->
    urlPayg = if (serverId?) then "/servers/#{serverId}/create/payg" else "/servers/create/payg"
    $.ajax 
      type: "GET",
      url: urlPayg,
      dataType: "html",
      success: (response) ->
        $("#jg-payg-widget").html(response)
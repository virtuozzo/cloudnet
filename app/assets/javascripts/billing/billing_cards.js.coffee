generate_card_html = ->
  return if account_cards.length <= 0
  
  card_output = ""
  _.each account_cards, (card) ->
    if card.primary is true
      primary = """
        <div class="pure-u-1-6">
          <span class="tags primary">Primary Card</span>
        </div>
      """
    else
      primary = """
        <div class="pure-u-1-6">
          <a href="/billing/make_primary?card_id=#{card.id}" data-method="post" rel="nofollow">
            <span class="tags make_primary">Make Primary</span>
          </a>
        </div>
      """

    card_output += 
      """
        <tr data-id="#{card.id}" data-validation="#{card.requires_validation}">
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

  renderCards = ->
    $(card_table).html(generate_card_html())
    $(card_table).find('i').tooltip()

  $(card_form).on 'add_card', (e) ->
    renderCards()

  renderCards()

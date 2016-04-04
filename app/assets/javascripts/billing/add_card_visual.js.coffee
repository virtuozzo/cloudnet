$ ->

  $monthField = $('#cc_month')
  $yearsField = $('#cc_year')
  $cvcField   = $('#cc_cvc')

  card_months   = new RegExp '(0[1-9]|1[0-2])'
  card_years    = new RegExp '(1[4-9]|2[0-4])'
  numeric_regex = new RegExp '^\\d+$'
  icon_regex    = new RegExp '(icon-([a-z]|[-_])+)', 'g'

  validClass    = 'valid'
  invalidClass  = 'invalid'
  
  topupPage = (location.search.split('topup_pg=')[1]||'').split('&')[0]

  simplyToggleClass = ($el, clazzName) ->
      flagButton = $el.hasClass(clazzName)
      $el[{true: 'removeClass', false: 'addClass'}[flagButton]](clazzName)
      return flagButton
      
  toggleBillingInfo = ($el) ->
    $parent = $el.parent()
    activeClass = simplyToggleClass($parent, 'open')
    $parent.find('.jg-disclosure').toggleClass('icon-arrow-down icon-arrow-up active')
    $tgbl = $parent.find('.jg-toggleable')
    if activeClass is false
      $tgbl.css
        display: 'inline-block'
      .animo( { animation: 'fadeInDown', duration: 0.2 })
    else
      $tgbl.animo( { animation: 'fadeOutUp', duration: 0.2, keep: true}, ->
        $tgbl.css
          display: 'none'
      )
      
    return
    
  $('.jg-toggle').click (e) ->
    toggleBillingInfo $(@)
  
  toggleBillingInfo $('#jg-add-card') unless account_cards.length
  
  if topupPage
    toggleBillingInfo $('#jg-auto-topup')
    $('html,body').animate({ scrollTop: $('#jg-auto-topup').offset().top }, 1000)

  reactivateTooltip = ($el) ->
    $el.tooltip
      animation:  true
    .tooltip('show')

  deactivateTooltip = ($el) ->
    $el.tooltip('hide')
    .tooltip('destroy')

  clearError = ->
    @removeClass('invalid')
    $field_status = @next('.field-status')
    $field_status.removeClass('icon-error')  

  removeClassRegex = ($field_status) ->
    $field_status[0].className = $field_status[0].className.replace(icon_regex, '')
    $field_status.removeClass('a')

  cardValidation = (obj) ->
    @removeClass(validClass + ' ' + invalidClass).addClass('valid')

    $field_status = @next('.field-status')
    deactivateTooltip($field_status)
    $field_status.removeClass('icon-error')

    removeClassRegex($field_status) 

    length = @val().length

    if length isnt 0
      $field_status.addClass(' icon-' + obj.card_type)
      $field_status.css
        display: 'block'

  validateFields = (obj) ->
    @removeClass(validClass + ' ' + invalidClass).addClass(obj.attrClass)

    $field_status = @next('.field-status')

    removeClassRegex($field_status) 

    length = @val().length

    if obj.type is 'error'
      reactivateTooltip $field_status   
    else
      deactivateTooltip $field_status

    if length is 0
      @removeClass('invalid')
      $field_status.css
        display: 'none'
      deactivateTooltip $field_status
    else
      $field_status.addClass('icon-' + obj.type).css
        display: 'block'

  checkIfCardIsValid = (result) ->
    deferred = Q.defer()

    @attr('maxlength', result?.card_type?.valid_length?[0] ? '')

    isNumeric = numeric_regex.test @val()

    if result.luhn_valid is false and result.length_valid is true
      err = 'Invalid card number, please check your credit card number.'
      deferred.reject err
    
    else if isNumeric is false
      err = "Invalid characters found in the input, please re-check this field"
      deferred.reject err
    
    else if result.card_type isnt null
      clearError.call(@)
      deactivateTooltip(@next('.field-status'))

    if result.card_type && @val().length >= 1 and isNumeric is true
      deferred.resolve result.card_type

    return deferred.promise

  checkNumericValidity = (val, options) ->
    minLimit  = options.minLimit || 0
    charLimit = options.charLimit || 2
    regex     = options.regex || /[a-z]/

    deferred = Q.defer()

    indicator = regex.test(val)
    length    = val.length

    if indicator is false && length in [0..charLimit] or indicator is false
      err = 
        msg:        "Invalid field, please check the month on the expiry date"
        attrClass:  'invalid'
        type:       'error'

      deferred.reject err

    else if indicator is true && length in [minLimit..charLimit]
      success = 
        msg:        invalidClass
        attrClass:  validClass
        type:       'success'

      deferred.resolve(success)

    return deferred.promise

  setupValidation = (regexFn, fn, options) ->
    $input_field    = @
    $input_field.keyup (e) ->
      val             = $input_field.val()
      fieldValidator  = fn.bind $input_field 

      # promise based function which handles all the call backs.
      regexFn(val, options)
      .then(fieldValidator)
      .catch(fieldValidator)
      .done()
    return

  setupValidation.call $monthField, checkNumericValidity, validateFields,
    minLimit:  2
    charLimit: 2
    regex:     card_months

  setupValidation.call $yearsField, checkNumericValidity, validateFields,
    minLimit:  2
    charLimit: 2
    regex:     card_years

  setupValidation.call $cvcField, checkNumericValidity, validateFields,
    charLimit: 4
    minLimit:  3
    regex:     numeric_regex

  $('#cc_number').validateCreditCard((result) ->
    $this = $('#cc_number')
    fieldValidator  = validateFields.bind($this)

    checkIfCardIsValid.call($this, result).then((result) ->
      obj = 
        msg:        'Valid card details'
        attrClass:  'valid'
        card_type:   result?.name
        type:       'success'

      cardValidation.call $this, obj
    ).catch((error) ->
      err = 
        msg:        error
        attrClass:  'invalid'
        type:       'error'
      fieldValidator(err)
    )
  ,
  accept: ['visa', 'mastercard', 'amex', 'diners_club_international', 'maestro', 'visa_electron', 'discover', 'jcb'])

  return
  

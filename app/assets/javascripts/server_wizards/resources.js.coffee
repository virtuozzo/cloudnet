$ ->
  @selectedTemplate = null
  @hoursTill  = null
  @costings   =
    hourly:     0.0000
    monthly:    0.00
    thisMonth:  0.00

  timeNow = ->
    date = moment().format()

  firstNextMonth = ->
    month     = moment().month()
    nextMonth = moment().add('months', 1).month()
    year      = moment().year()
    date      = moment([year, month, 1]).month(nextMonth).format()
    return date

  timeTillNextMonth = =>
    m = moment(firstNextMonth())
    t = timeNow()

    @hoursTill = m.diff(t, 'hours')
    $('#resource-hours').text("@#{@hoursTill} hours")
    setTimeout(->
      timeTillNextMonth()
    , 3600000)

  setDate = ->
    date = firstNextMonth()
    firstOfMonth = moment(date).format("LL")
    $('#resource-date').text("#{firstOfMonth}")

  setDate()
  timeTillNextMonth()

  $('#resourceTabs a').click (e) ->
    e.preventDefault()
    $(this).tab('show')
    $(this).parent('li').addClass('active')

  $costs            = $('span.total-cost')
  $boxes            = $('ul.package-boxes').find('> li')
  $distro           = $('#server_wizard_os_type') # The select boxes dropdown for distros
  $template         = $('#template')
  $hourly           = $('#hourly')
  $monthly          = $('#monthly')
  $templateId       = $('#server_wizard_template_id') # The hidden field for the template ID
  $disk             = $('#server_wizard_disk_size')
  $memory           = $('#server_wizard_memory')
  $cpus             = $('#server_wizard_cpus')
  $ips              = $('#server_wizard_ip_addresses')
  $resourcesSummary = $('#resources-selection').find('.step-value')
  $provisionerRole  = $('#server_wizard_provisioner_role')

  createMonthlyTooltip = =>
    $costs.tooltip
      animation:  true
      html: true
      title: monthlyCostHtml()

  destroyMonthlyTooltip = -> $costs.tooltip('destroy')

  removeBoxClass = ->
    $boxes.each -> $(this).removeClass('active')

  templateList = _.map templates, (templateGroup) ->
    return templateGroup

  simpleList = _.flatten templateList, true

  $elements = {}

  cpus      = _.findWhere defaults, field: "cpus"
  memory    = _.findWhere defaults, field: "memory"
  disk_size = _.findWhere defaults, field: "disk_size"

  previousValues =
    memory: $memory.val()
    cpus: $cpus.val()
    disk_size: $disk.val()

  formatCurrency = (data, round=6) ->
    value = data / millicents_dollar
    money = accounting.formatMoney(value, "$", round, ",")
    return money

  setBandwidth = ->
    bw_per_mb = selected_location.inclusive_bandwidth / 1024.0
    bandwidth = bw_per_mb * (Math.floor($memory.val() / 128) * 128)

    $("#inclusive-bandwidth").html "#{bandwidth.toFixed(1)} GB"

  setPrices = ->
    hourly_price = 0
    hourly_price += $memory.val() * selected_location.prices.price_memory
    hourly_price += $cpus.val() * selected_location.prices.price_cpu
    hourly_price += $disk.val() * selected_location.prices.price_disk
    hourly_price += ($ips.val() - 1) * selected_location.prices.price_ip_address

    if @selectedTemplate?
      hourly_price += @selectedTemplate.hourly_cost

    monthly_price = hourly_price * max_hours

    
    if @server
      old_hourly_price = 0
      old_hourly_price += @server.memory * selected_location.prices.price_memory
      old_hourly_price += @server.cpus * selected_location.prices.price_cpu
      old_hourly_price += @server.disk_size * selected_location.prices.price_disk
      old_hourly_price += (@server.ip_addresses - 1) * selected_location.prices.price_ip_address
      old_hourly_price += @selectedTemplate.hourly_cost if @selectedTemplate?
      today_price = (hourly_price - old_hourly_price) * hours_remaining
    else
      today_price = hourly_price * hours_remaining


    $("#hourly-price").html formatCurrency(hourly_price)
    $("#monthly-price").html formatCurrency(monthly_price, 2)
    $("#today-price").html formatCurrency(today_price, 2)

  setResources = ->
    setBandwidth()
    setPrices()

    resources =
      memory:
        amount: $memory.val()
        unit:   'MB'
      disk_size:
        amount: $disk.val()
        unit:   'GB'
      cpus:
        amount: $cpus.val()
        unit:   'Core(s)'

    keys = _.keys resources
    _.each keys, (key) ->
      $resourcesSummary.find("b.resources-#{key}").text("#{resources[key].amount} #{resources[key].unit},")

  setTemplateName = (template) ->
    $resourcesSummary.find('h4').removeClass (index, css) ->
      (css.match(/\bos-\S+/g) or []).join " "
    .addClass("os-#{template.os_distro.toLowerCase()}")

    $resourcesSummary.find('h4 b.template-name').text("#{template.name}")

  setTemplatePricing = (template) ->
    if server && server.provisioner_role
      template = provisionerTemplates['linux-docker'][0]
    @selectedTemplate = template
    $("#template-hourly-price").html formatCurrency(template.hourly_cost)
    $("#template-monthly-price").html formatCurrency(template.hourly_cost * max_hours)

  updateSliderRange = (options) ->
    if options?.max isnt null and options?.min isnt null
      $elements[options.field].noUiSlider
        range:
          min: options.min,
          max: options.max
      , true
    return

  setRange = (options, template) ->
    options.min = template["min_#{options.field}"]
    options.min = if options.min is undefined then 1 else options.min
    updateSliderRange(options)

  updateSliderValue = (options, value) ->
    updateSliderRange(options)
    $elements[options.field].val(value, true)

  # updates sliders if current slider value is smaller
  # then 'value' passed as parameter
  updateSliderIfSmaller = (options, value) ->
    updateSliderRange(options)
    el = $elements[options.field]
    el.val(value) if parseInt(el.val(),10) < value

  initializeSlider = (options) ->
    $elements[options.field].noUiSlider
      start: options.min
      connect: "lower"
      range:
        min: options.min,
        max: options.max
      serialization:
        format:
          decimals: 0
        lower: [
          new $.noUiSlider.Link({target: $("#server_wizard_#{options.field}")})
        ]

    .on 'slide', (e) ->
      setResources()
      removeBoxClass()

    .on 'set', (e) ->
      setResources()

    setResources()

    return

  initializeAllSliders = (arrOptions) ->
    template = parseInt $template.val()
    temp     = _.findWhere simpleList, id: template

    _.each arrOptions, (options) ->
      $elements[options.field] = $("##{options.field}-slider")
      fieldValue = $("#server_wizard_#{options.field}").val()

      if fieldValue.length < 1
        initializeSlider options
      else
        initializeSlider options
        if $template.val().length >= 1
          setRange(options, temp)
          updateSliderValue(options, fieldValue)

  initializeAllSliders(defaults)

  upperCase = (string) -> return string.charAt(0).toUpperCase() + string.slice(1)

  updateSliderLimits = (data) ->
    updateSliderIfSmaller(cpus, 1)

    updateSliderIfSmaller
      min: data.min_memory
      max: memory.max
      field: "memory"
      , data.min_memory

    updateSliderIfSmaller
      min: data.min_disk
      max: disk_size.max
      field: "disk_size"
      , data.min_disk

    return

  # Given data from a package box, update the sliders to coorespond to those values
  setSliderPositions = (data) ->
    _.each data, (value, key) ->
      options =
        field: key
        min:   null
        max:   null
      value = parseInt(value)
      updateSliderValue options, value

    setResources()

  arr = _.keys templates

  distroSelect = _.map arr, (value, index) ->
    string  = value.split('-')
    distro  = upperCase(string.pop())

    obj =
      id: arr[index]
      distro: distro

    return obj

  distroFormat = (item) ->
      html = """
        <span class="jg-option-field os os-#{item.distro.toLowerCase()}">#{item.distro}</span>
      """
      return html

  templateFormat = (item) ->
    html = """
      <span class="jg-option-field">#{item.name}</span>
    """
    return html

  # What to do once a template has been chosen
  templateChosen = (template) ->
    updateSliderLimits template
    setTemplateName template
    setTemplatePricing template
    $templateId.val template.id # Set the hidden field that stores the template ID for the form
    setResources()

  # Fill the template dropdown
  populateTemplateSelect = (distro) ->
    if distro
      options = templates[distro]
      enable = true
    else
      options = []
      enable = false

    $template.select2
      placeholder: 'Select a template'
      data:
        results: options
      formatSelection: templateFormat
      formatResult: templateFormat
    .on 'change', (e) ->
      data = template = e.added
      templateChosen(template)
    .select2 'enable', enable

  # Populate the "Select a distro" dropdown
  $distro.select2
    placeholder: 'Select a distro'
    data:
      results:  _.sortBy distroSelect, 'distro'
    formatSelection: distroFormat
    formatResult: distroFormat

  # Once a distro has been chosen, populate the template dropdown with that distro's available
  # templates.
  .on 'change', (e) ->
    data = e.added
    distro = data.id
    populateTemplateSelect(distro)
    # Ensure there is no template selected yet
    $templateId.val(-1)

  # Set template to Docker provisioner template
  $provisionerRole
  .on 'change', (e) ->
    template = provisionerTemplates['linux-docker'][0]
    templateChosen(template)
    $template.val template.id
  .select2 'enable', true

  # Initialise the templates dropdown
  if server
    # Preselect the server's distro and template if editing an existing server
    distro_of_existing_server = "#{server.template.os_type}-#{server.template.os_distro}"
    $distro.select2 'val', distro_of_existing_server
    populateTemplateSelect distro_of_existing_server
    templateChosen server.template
  else
    # Show an empty and disabled template dropdown
    populateTemplateSelect()

  # What to do when clicking on a package box
  $('ul.package-boxes li').click (e) ->
    e.preventDefault()
    removeBoxClass()
    data = $(this).data('package-values')
    setSliderPositions(data)
    $(this).addClass('active')

  assignTemplateValue = (template) ->
    $template.val template.id
    $template.select2 'enable', true
    $template.trigger jQuery.Event('change', added: template)

  checkTemplateValue = ->
    fieldValue  = $templateId.val()
    distroValue = $distro.val()

    unless fieldValue.length < 1
      val = parseInt(fieldValue)
      selectedTemplate  = _.findWhere templates[$distro.val()], id: val

      if selectedTemplate
        setTemplateName(selectedTemplate)
        setTemplatePricing(selectedTemplate)
        assignTemplateValue(selectedTemplate)
        setResources()

        _.each previousValues, (value, key) ->
          if fieldValue.length >= 1
            $elements[key].val(value, true)
    else if distroValue.length > 1
      selectedDistro = _.findWhere distroSelect, id: $distro.val()
      if selectedDistro
        $distro.trigger jQuery.Event('change', added: selectedDistro)

  formatPriceElements = ->
    _.each $(".price"), (element) ->
      price = parseFloat $(element).html()
      $(element).html(formatCurrency(price))

    _.each $(".price-2"), (element) ->
      price = parseFloat $(element).html()
      $(element).html(formatCurrency(price, 2))


  checkTemplateValue()
  formatPriceElements()

  server_wizard_next_step_button = "#server_wizard_next_step"
  $("#new_server_wizard").submit (event) ->
    $(server_wizard_next_step_button).text("Please wait...")
    $(server_wizard_next_step_button).attr('disabled', 'disabled')

  if activePack
    # Set the sliders to the existing server's resources
    slider_data = $('.package-boxes li.active').data('package-values')
  else
    $paramsData = $('.resource-tabs').data('params')
    sum = _($paramsData).reduce ((memo, num) -> memo + num), 0
    slider_data = $paramsData if sum > 0

  setSliderPositions(slider_data)

  # Until the Federation supports disk resizing hide and fade the slider
  $('#disk_size-slider').attr('disabled', 'disabled') if server && server.template.os_distro.match(/bsd/)

  enableWizardTemplateTabs = ->
    $('#jg-tabs li a').on 'click', (e) ->
      e.preventDefault()

      allDivs = _.map $('#jg-tabs li a'), (el) -> $(el).attr('href')
      $('#jg-tabs li').removeClass 'active'
      _.each allDivs, (el) -> $(el).hide()

      activeTab = $(this).attr('href')
      $(this).parent().addClass 'active'
      $(activeTab).show()
      
      if !server
        $provisionerRole.select2('val', null)
        $distro.select2('val', null)
        $template.select2('val', null)

    if $('#server_wizard_provisioner_role').val() != ''
      $('#jg-tabs li:nth-child(2) a').click()
    else
      $('#jg-tabs li:first a').click()
    
    if server
      if server.provisioner_role
        $("#server-distributions").hide()
        $('#server_wizard_provisioner_role').val(server.provisioner_role).trigger("change")
      else
        $("#server-apps").hide()

  enableWizardTemplateTabs()

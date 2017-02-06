scope = this

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

  $('#templateTabs a').click (e) ->
    e.preventDefault()
    $(this).tab('show')
    $(this).parent('li').addClass('active')

    $provisionerRole.val([])
    $distro.val([])
    $template.val([])

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
  defaultPhoto      = "61344979"
  $locationField    = $('#server_wizard_location_id')
  $distroSelect     = []

  if $.isEmptyObject(templatesJson)
    templates = []
  else
    templates = templatesJson

  if $.isEmptyObject(selectedLocation)
    selected_location = []
  else
    selected_location = selectedLocation

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

    $("#memory-price").html formatCurrency(($memory.val() * selected_location.prices.price_memory * 672).toFixed(2), 2)
    $("#cpu-price").html formatCurrency(($cpus.val() * selected_location.prices.price_cpu * 672).toFixed(2), 2)
    $("#disk-price").html formatCurrency(($disk.val() * selected_location.prices.price_disk * 672).toFixed(2), 2)

    $("#hourly-price").html formatCurrency(hourly_price)
    $("#monthly-price").html formatCurrency(monthly_price, 2)
    $("#today-price").html formatCurrency(today_price, 2)

  setResources = ->
    return if $.isEmptyObject(selected_location)

    setBandwidth()
    setPrices()
    hideSlider()

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

  hideSlider = ->
    if selected_location.budget_vps
      $('#resourceTabs li.packages-tab a').trigger('click')
      $('#resourceTabs li.slider-tab').hide()
    else
      $('#resourceTabs li.slider-tab').show()

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
    $("#template-monthly-price").html formatCurrency(template.hourly_cost * max_hours, 2)

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
    min_memory = Math.max(data.min_memory, memory.min)
    min_disk_size = Math.max(data.min_disk, disk_size.min)

    updateSliderIfSmaller(cpus, 1)

    updateSliderIfSmaller
      min: min_memory
      max: memory.max
      field: "memory"
      , data.min_memory

    updateSliderIfSmaller
      min: min_disk_size
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

  setDistroSelect = (templates) ->
    arr = _.keys templates

    $distroSelect = _.map arr, (value, index) ->
      string  = value.split('-')
      distro  = upperCase(string.pop())

      obj =
        id: arr[index]
        distro: distro

      return obj

  setDistroSelect(templates)


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
  populateDistros = ->
    $template.val([])
    $distro.val([])
    
    $distro.select2
      placeholder: 'Select a distro'
      data:
        results:  _.sortBy $distroSelect, 'distro'
      formatSelection: distroFormat
      formatResult: distroFormat
    # Once a distro has been chosen, populate the template dropdown with that distro's available templates.
    .on 'change', (e) ->
      data = e.added
      distro = data.id
      populateTemplateSelect(distro)
      # Ensure there is no template selected yet
      $template.val([])
  
  populateDistros()

  # Set template to Docker provisioner template
  loadProvisionerRole = (provisioner_templates) ->
    if !($.isEmptyObject(provisioner_templates))
      $provisionerRole
      .on 'change', (e) ->
        template = provisioner_templates['linux-docker'][0]
        templateChosen(template)
        $template.val template.id
      .select2 'enable', true
    else
      $provisionerRole.val([])
      $provisionerRole.select2 'enable', false

  # Initialise the templates dropdown
  if server
    # Preselect the server's distro and template if editing an existing server
    distro_of_existing_server = "#{server.template.os_type}-#{server.template.os_distro}"
    $distro.select2 'val', distro_of_existing_server
    populateTemplateSelect distro_of_existing_server
    templateChosen server.template
  else if osType
    $distro.select2 'val', osType
    populateTemplateSelect osType
    $templateId.val(templateId) if templateId
  else
    # Show an empty and disabled template dropdown
    populateTemplateSelect()

  # What to do when clicking on a package box
  loadPackageBoxes = ->
    $('ul.package-boxes li').click (e) ->
      e.preventDefault()
      removeBoxClass()
      data = $(this).data('package-values')
      setSliderPositions(data)
      $(this).addClass('active')

  loadPackageBoxes()

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
      selectedDistro = _.findWhere $distroSelect, id: $distro.val()
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

  enableTemplateTabs = ->
    $('#jg-tabs li a').on 'click', (e) ->
      e.preventDefault()

      allDivs = _.map $('#jg-tabs li a'), (el) -> $(el).attr('href')
      $('#jg-tabs li').removeClass 'active'
      _.each allDivs, (el) -> $(el).hide()

      activeTab = $(this).attr('href')
      $(this).parent().addClass 'active'
      $(activeTab).show()

      if !server
        $provisionerRole.val([])
        $distro.val([])
        $template.val([])

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

  enableTemplateTabs()

  #----------------------------------------------------
  # Functions for the 500px downloading and the MapBox
  # Pop up boxes
  #----------------------------------------------------

  _500px.init(
    sdk_key: five_hundred_px_key
  )

  generatePopupContent = (photo, data) ->
    newContent =
      """
        <div class="location_header">
          <ul id="image_links" class="pure-g">
            <li class="icon-hover jg-hover-trans pure-u">
              <a target="_blank" class="icon-user" href="http://500px.com/#{photo.data.user.username}"></a>
              <span class="jg-animate animated fadeInRight">#{photo.data.user.username}</span>
            </li>
            <li class="icon-hover pure-u">
              <a target="_blank" class="icon-link" href="http://500px.com#{photo.data.photo.url}"></a>
            </li>
          </ul>
          <div class="title">#{photo.data.photo.name}</div>

          <div class="map_location">
            #{photo.data.first.img}
          </div>
        </div>
        <div class="location_body">
          <div class="country_city">
            <img src='/assets/images/flags/flat/24/#{data.country}.png'/>
            <a target="_blank" class="popup location_name" href="https://www.google.co.uk/maps/place/#{data.city}">
              <b>#{data.city}</b>, #{data.country_name}</b>
            </a>
            <ul class="location_info pure-g">
              <li class="pure-u-1-3"><b class="pure-u-1">Provider</b><span class="pure-u-1"><a href="#{data.provider_link}" target="_blank">#{data.provider}</a></span></li>
              <li class="pure-u-1-3"><b class="pure-u-1">Type</b><span class="pure-u-1">#{if data.budget_vps then 'Budget VPS' else 'Cloud'}</span></li>
              #{if data.ssd_disks then '<li class="pure-u-1-3"><b class="pure-u-1">SSD Disks</b><span class="pure-u-1">Yes</span></li>' else ''}
            </ul>
          </div>
        </div>
      """
    return newContent

  grabPhotoId = (ids) ->
    return defaultPhoto if ids == null

    split = ids.split(',')
    return defaultPhoto if split.length == 0
    return split[Math.floor(Math.random()*split.length)];

  fetchPhoto = (city, id, marker = {}) ->
    deferred = Q.defer()
    _500px.api "/photos/#{id}", (response) ->
      if response.error
        console.log city + ": " + response.error_message
        _500px.api "/photos/#{defaultPhoto}", (response) =>
          if response.error
            deferred.reject(response.err)
          else
            deferred.resolve(city: city, data: cityPhotoObject(response.data.photo), marker: marker)
      else
        deferred.resolve(city: city, data: cityPhotoObject(response.data.photo), marker: marker)

    return deferred.promise

  fetchPhotoByCity = (city, id, marker = {}) ->
    deferred = Q.defer()
    _500px.api "/photos/search", {tag: city, rpp: 1, image_size: 4}, (response) ->
      if response.err?
        deferred.reject(response.err)
      deferred.resolve(city: city, data: cityPhotoObject(response.data.photos[0]), marker: marker)

    return deferred.promise

  cityPhotoObject = (obj) ->
    user:   obj?.user
    photo:  obj
    first:
      url:  "http:://500px.com/" + obj?.url
      img:
        """
          <img src="#{obj?.image_url}" width="340" height ="240"/>
        """

  generateRect = (lat, lng, r = 0.5) ->
    rect =
      lat:
        min: parseFloat(lat) - r
        max: parseFloat(lat) + r
      lng:
        min: parseFloat(lng) - r
        max: parseFloat(lng) + r

    return rect

  createPhotosObject = (obj, layer) ->
    first = obj.photos[0]
    photos =
      marker: layer
      first:
        owner:     first.owner_name
        owner_url: first.owner_url
        photo_url: first.photo_url
        img:
          """
            <img src="#{first.photo_file_url}" width="340" height ="240"/>
          """
      arr: obj.photos

    return photos

  default_icon =
    iconUrl: inactive_pin
    iconSize: ['26', '32']
    iconAnchor: ['13', '32']
    popupAnchor: [-2, -35]

  active_icon =
    iconUrl: active_pin
    iconSize: ['26', '32']
    iconAnchor: ['13', '32']
    popupAnchor: [-2, -35]

  _.mixin changePropertyName: (object, oldKey, newKey) ->
    object[newKey] = object[oldKey]
    delete object[oldKey]
    return object


  resetMarkers = (markers) ->
    _.each markers, (marker) ->
      marker.setIcon(L.icon(default_icon))

      return

  toggleMarkerPin = (icon, marker) ->
    if icon.iconUrl is inactive_pin
      return marker.setIcon(L.icon(active_icon))

    else if icon.iconUrl is active_pin
      return marker.setIcon(L.icon(default_icon))

    return

  setupMapBeta = ->
    geojson = new helpers.GeoJsonBuilder(locations, inactive_pin).generate()
    map = L.mapbox.map 'jg-map', mapbox_key,
      accessToken: mapboxPublicToken,
      minZoom: 2,
      maxZoom: 12
      closePopupOnClick: false
    map.setView([20.0, 0.0], 2)

    clusters = new L.MarkerClusterGroup
      maxClusterRadius: 20
      animateAddingMarkers: true

    markers = []

    geoJsonLayer = L.geoJson geojson,
      onEachFeature: (feature, layer) ->

        d       = feature?.properties
        rect    = generateRect d.latitude, d.longitude
        city    = d.city
        popupContent =
            """
              <div class="location_body">
                <div class="country_city">
                  <img src='/assets/images/flags/flat/24/#{feature.properties.country}.png'/>
                  <a target="_blank" class="popup" href="https://www.google.co.uk/maps/place/#{feature.properties.city}">
                    <b>#{feature.properties.city}</b>, #{feature.properties.country}
                  </a>
                </div>
              </div>
            """
        layer.bindPopup(popupContent)
        id = grabPhotoId(d.photo_ids)
        if id
          fetchPhoto(city, id, layer).then (photo) ->
            marker = photo.marker
            data   = marker.feature.properties

            newContent = generatePopupContent(photo, data)
            photo.marker.bindPopup(newContent)

            unless $.isEmptyObject(selected_location)
              popUp(selected_location.id)

        else fetchPhotoByCity(city, id, layer).then (photo) ->
          marker = photo.marker
          data   = marker.feature.properties
          newContent = generatePopupContent(photo, data)
          photo.marker.bindPopup(newContent)

          unless $.isEmptyObject(selected_location)
            popUp(selected_location.id)

        layer.options.riseOnHover = true
        layer.options.title       =
          """
          [#{d.provider}, #{d.country}]
          """
        layer.setIcon(L.icon(feature.properties.icon))

        markers.push layer

        layer.on 'click', (e) ->
          marker  =   e.target
          icon    =   marker.options.icon.options
          data    =   marker?.feature?.properties
          # map.panTo(marker.getLatLng())
          # marker.bounce({duration: 400, height: 10})
          clusters.zoomToShowLayer(marker, (e) -> )
          resetMarkers(markers)
          return if data is null or undefined
          toggleMarkerPin icon, marker
          $locationField.select2("val", data.id).trigger("change")

    map.on 'addlayer', (e) ->
      marker  = e.target
      data    =   marker?.feature?.properties

    clusters.addLayer(geoJsonLayer)
    map.addLayer(clusters)

    popUp = (loc) ->
      geoJsonLayer.eachLayer (marker) ->
        if parseInt(marker?.feature?.properties.id) is parseInt(loc)
          id = marker._leaflet_id
          clusters.zoomToShowLayer(marker, (e) ->
              map._layers[id].openPopup()
            )
          # marker.bounce({duration: 400, height: 10})
          resetMarkers(markers)
          toggleMarkerPin marker.options.icon.options, marker

    $locationField.on 'change', (e) ->
      popUp($(this).select2('data').id)

    # Disable scroll zoom handlers.
    map.touchZoom.disable()
    map.scrollWheelZoom.disable()

    #map.featureLayer.setGeoJSON(geojson)
    return

  #----------------------------------------------------
  # Functions for formatting countries and displaying
  # the relevant Select2 dropdowns
  #----------------------------------------------------

  _.mixin select2Array: (data, fields, options) ->
    i = 0

    key = options?.key || 'integer'

    collection = _.map data, (value, index) ->
      data = _.pick value, fields
      data['id'] = switch key
        when true then index
        when 'integer' then i
        else value[key]

      i++
      return data
    return collection

  # cityFormat = (location) ->
  #   html = """
  #     <img src='/assets/images/flags/flat/16/#{location.country}.png'/>
  #     <span class="jg-option-field">#{location.city}</span>
  #   """
  #   return html
  #
  # cities = _.select2Array locations, ['city', 'country'], key: 'id'
  # $locationField.select2
  #   placeholder:        'Select a location'
  #   data: ->
  #     return {results: _.sortBy cities, 'city', text: 'city'}
  #   formatSelection:  cityFormat
  #   formatResult:     cityFormat
  # .select2 'enable', true

  if !server
    setupMapBeta()

  $locationField.on 'change', (e) ->
    $.ajax
      type: "GET",
      url: "/locations/#{this.value}",
      dataType: "JSON",
      success: (response) ->
        selected_location = response
        setResources()

    $.ajax
      type: "GET",
      url: "/locations/#{this.value}/templates",
      dataType: "JSON",
      success: (response) ->
        templates = response
        setDistroSelect(templates)
        populateDistros()
        populateTemplateSelect()

    $.ajax
      type: "GET",
      url: "/locations/#{this.value}/provisioner_templates",
      dataType: "JSON",
      success: (response) ->
        loadProvisionerRole(response)

    $.ajax
      type: "GET",
      url: "/locations/#{this.value}/packages",
      dataType: "HTML",
      success: (response) ->
        $("#location-packages").html(response)
        formatPriceElements()
        $boxes = $('ul.package-boxes').find('> li')
        loadPackageBoxes()

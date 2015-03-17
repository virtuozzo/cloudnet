scope = this

$ ->
  #----------------------------------------------------
  # Functions to make the tabs work (including filtering)
  #----------------------------------------------------
  
  hideFilteringContent = (activeTab) ->
    if activeTab == "#step-wizard-list"
      $("#filteringButton, #filteringContent").show()
    else
      $("#filteringButton, #filteringContent").hide()

  enableWizardTabs = ->
    $('#jg-tabs li a').on 'click', (e) ->
      e.preventDefault()

      allDivs = _.map $('#jg-tabs li a'), (el) -> $(el).attr('href')
      $('#jg-tabs li').removeClass 'active'
      _.each allDivs, (el) -> $(el).hide()

      activeTab = $(this).attr('href')
      $(this).parent().addClass 'active'
      $(activeTab).show()

      hideFilteringContent(activeTab)

    $('#jg-tabs li:first a').click()

  enableFilteringPanel = ->
    $('#filteringButton').on 'click', (e) ->
      e.preventDefault()

      filterButton = $('#filteringButton')
      if filterButton.hasClass('active') 
        filterButton.removeClass('active')
        $('.jg-filter-content').hide()
      else
        filterButton.addClass('active')
        $('.jg-filter-content').show()
    $('.jg-filter-content').hide()

  enableWizardTabs()
  enableFilteringPanel()

  #----------------------------------------------------
  # Add our direct filter onto the datatable
  #----------------------------------------------------

  costFilterTypes = [
    { name: 'memory', index: 2 }, 
    { name: 'disk', index: 3 }, 
    { name: 'cpu', index: 4 }
  ]

  numberFilterTypes = [
    { name: 'bandwidth', index: 5 },
    { name: 'cloud_index', index: 6 }
  ]

  $.fn.dataTable.ext.afnFiltering.push (settings, data, dataIndex) ->
    withinBounds = true

    _.each costFilterTypes, (filter) ->
      lower = parseFloat($("#value-#{filter.name} .units-lower").val()) * millicents_dollar
      upper = parseFloat($("#value-#{filter.name} .units-higher").val()) * millicents_dollar

      if parseFloat(data[filter.index]) < lower && Math.abs(parseFloat(data[filter.index]) - lower) > 0.00001
        withinBounds = false
      else if parseFloat(data[filter.index]) > upper && Math.abs(parseFloat(data[filter.index]) - upper) > 0.00001
        withinBounds = false

      withinBounds = true if lower == NaN || upper == NaN

    _.each numberFilterTypes, (filter) ->
      lower = parseFloat($("#value-#{filter.name} .units-lower").val())
      upper = parseFloat($("#value-#{filter.name} .units-higher").val())

      if parseFloat(data[filter.index]) < lower && Math.abs(parseFloat(data[filter.index]) - lower) > 0.00001
        withinBounds = false
      else if parseFloat(data[filter.index]) > upper && Math.abs(parseFloat(data[filter.index]) - upper) > 0.00001
        withinBounds = false

      withinBounds = true if withinBounds != false && (lower == NaN || upper == NaN)

    return withinBounds

  #----------------------------------------------------
  # Functions to assist with the dynamic table
  #----------------------------------------------------
  formatCurrency = (data, round=6) ->
    value = data / millicents_dollar
    money = accounting.formatMoney(value, "$", round, ",")
    return money

  dataTable = $('#step-wizard-cloud-table').dataTable
    "paging": false,
    "sDom": "",
    "columnDefs": [{ 
        "targets": 2, 
        "render": ( data, type, row, meta ) -> 
          if type != "display" 
            return data
          formatCurrency(data) + " <i> / Hour</i>"
      }, { 
        "targets": 3, 
        "render": ( data, type, row, meta ) -> 
          if type != "display" 
            return data
          formatCurrency(data) + " <i> / Hour</i>"
      }, { 
        "targets": 4, 
        "render": ( data, type, row, meta ) -> 
          if type != "display" 
            return data
          formatCurrency(data) + " <i> / Hour</i>"
      }, { 
        "targets": 5, 
        "render": ( data, type, row, meta ) -> 
          if type != "display" 
            return data

          if parseInt(data) >= 1000
            return (data / 1000.0).toFixed(1) + " TB <i class='small'> (per GB of RAM)</i>" 
          else
            return data + " GB <i class='small'> (per GB of RAM)</i>" 
      }
    ]

  budgetTable = $('#step-wizard-budget-table').dataTable
    "paging": false,
    "sDom": ""

  assignClickHandlerForDataTable = (table) ->
    table.on 'click', 'tr', ->
      id = parseInt($(this).data('id'))
      location = _.find locations, (l) -> l.id == id
      assignValues(location)
  
      dataTable.$('tr.selected').removeClass('selected');
      budgetTable.$('tr.selected').removeClass('selected');
      $(this).addClass('selected');

  assignClickHandlerForDataTable(dataTable)
  assignClickHandlerForDataTable(budgetTable)

  selectRowOnDataTable = (location) ->
    id = location.id
    row = _.find dataTable.$('tr'), (el) -> parseInt($(el).data('id')) == id
    if row is undefined
      row = _.find budgetTable.$('tr'), (el) -> parseInt($(el).data('id')) == id

    dataTable.$('tr.selected').removeClass('selected');
    budgetTable.$('tr.selected').removeClass('selected');
    $(row).addClass('selected');

  #----------------------------------------------------
  # Functions to assist with the Filtering Sliders and 
  # filtering the subsequent data table
  #----------------------------------------------------

  initializeSlider = (options, decimals=7) ->
    $(options.field).noUiSlider
      start: [options.min, options.max],
      connect: true,
      range:
        min: options.min,
        max: options.max
      serialization:
        format:
          decimals: decimals
        lower: [
          new $.noUiSlider.Link {target: $(options.lower)} 
        ],
        upper: [
          new $.noUiSlider.Link {target: $(options.upper)}
        ]      
    .on 'slide', ->
      dataTable.fnDraw()
      return
    .on 'set', ->
      dataTable.fnDraw()
      return

    return

  _.each costFilterTypes, (el) ->
    options = 
      field: "##{el.name}-slider"
      min: $("##{el.name}-slider").data('min') / millicents_dollar
      max: $("##{el.name}-slider").data('max') / millicents_dollar
      lower: "#value-#{el.name} .units-lower"
      upper: "#value-#{el.name} .units-higher"

    initializeSlider(options)

  _.each numberFilterTypes, (el) ->
    options = 
      field: "##{el.name}-slider"
      min: $("##{el.name}-slider").data('min')
      max: $("##{el.name}-slider").data('max')
      lower: "#value-#{el.name} .units-lower"
      upper: "#value-#{el.name} .units-higher"

    initializeSlider(options, 0)

  dataTable.fnDraw()


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
    defaultPhoto = "61344979"

    return defaultPhoto if ids == null
    
    split = ids.split(',')
    return defaultPhoto if split.length == 0
    return split[Math.floor(Math.random()*split.length)];

  fetchPhoto = (city, id, marker = {}) ->
    deferred = Q.defer()
    _500px.api "/photos/#{id}", (response) ->
      if response.err?
        deferred.reject(response.err)
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
    photos =
      user:   obj.user
      photo:  obj
      first:
        url:  "http:://500px.com/" + obj.url
        img:
          """
            <img src="#{obj.image_url}" width="340" height ="240"/>
          """

    return photos


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

  requestPhotos = (layer, lat, lng, maxPhoto = 5) ->
    deferred = Q.defer()
    $.ajax
      url: "http://www.panoramio.com/map/get_panoramas.php?set=public&from=0&to=#{maxPhoto}&minx=#{lng.min}&miny=#{lat.min}&maxx=#{lng.max}&maxy=#{lat.max}&size=medium&mapfilter=true"
      dataType: 'jsonp'
      type:"GET"
      contentType: "jsonp"
      success: (data) ->
        deferred.resolve(createPhotosObject(data, layer))
      error: (xhr, err) ->
        deferred.reject(err)

    return deferred.promise

  $country        = $('#country')
  $city           = $('#city')
  $provider       = $('#provider')
  $summary        = $('#location-selection')
  $locationField  = $('#server_wizard_location_id')
  $summaryTitle   = $summary.find('.step-value')

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

  _.mixin geoJson: (locations) ->
    arr = []

    geoJson =
      type: 'Feature'
      geometry:
        type: 'Point'
        coordinates: null
      properties:
        icon: default_icon
    _.each locations, (location) ->
      # Copy the GeoJSON template, clone attributes and then set attributes based on location
      data                        = _.clone geoJson
      data.geometry               = _.clone geoJson.geometry
      data.geometry.coordinates   = [location.longitude, location.latitude]
      data.properties             = _.extend location, data.properties
      
      arr.push data

    return arr

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
    geojson = _.geoJson locations

    map = L.mapbox.map 'jg-map', mapbox_key,
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

        else fetchPhotoByCity(city, id, layer).then (photo) ->
          marker = photo.marker
          data   = marker.feature.properties
          newContent = generatePopupContent(photo, data)
          photo.marker.bindPopup(newContent)
        
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
          map.panTo(marker.getLatLng())
          marker.bounce({duration: 400, height: 10})
          resetMarkers(markers)
          return if data is null or undefined
          toggleMarkerPin icon, marker
          $locationField.val(data.id)
          assignValues(data)

    map.on 'addlayer', (e) ->
      marker  = e.target
      data    =   marker?.feature?.properties

    clusters.addLayer(geoJsonLayer)
    map.addLayer(clusters)
    
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

  countries = {}
  _.each (_.groupBy locations, (location) -> return location.country), (v, k) ->
    countries[k] = 
      country:  v[0].country
      name: v[0].country_name
      cities: _.groupBy v, (location) -> return location.city

    _.each countries[k].cities, (city) ->
      city.country = v[0].country

  countriesSelect = _.select2Array countries, ['country', 'name'], {key: 'country'}

  clearData = (selects) -> 
    _.each selects, (select) -> $(select).select2 'val', ''
    $locationField.val(-1)
    hideSummary()


  countryFormat = (location) ->
      html = """
        <img src='/assets/images/flags/flat/16/#{location.id}.png'/>
        <span class="jg-option-field">#{location.name}</span>
      """
      return html

  cityFormat = (location) ->
      html = """
        <img src='/assets/images/flags/flat/16/#{location.country}.png'/>
        <span class="jg-option-field">#{location.id}</span>
      """
      return html

  providerFormat = (location) ->
    return location.provider

  countryOptions = 
    placeholder: 'Select a country'
    data: ->
      results:        _.sortBy countriesSelect, 'name'
      text:           'name'
    formatSelection:  countryFormat
    formatResult:     countryFormat

  # Create options for the Country Select2
  $country.select2 countryOptions

  .on 'change', (e) ->
    data = e.added
    clearData($city)

    $provider.select2
      placeholder:        'Select a provider'
      data:               {}
    .select2 'enable', false


    $city.select2 
      placeholder:        'Select a city'
      data: ->
        citiesSelect = _.select2Array countries[data.country].cities, ['country'], key: true
        return {results: citiesSelect, text: 'city'}

      formatSelection:  cityFormat
      formatResult:     cityFormat
    .select2 'enable', true

  cities = _.select2Array locations, ['city', 'country'], key: 'city'

  $city.select2
    placeholder:        'Select a city'
    data: ->
      return {results: _.sortBy cities, 'city', text: 'city'}
    formatSelection:  cityFormat
    formatResult:     cityFormat

  .on 'change', (e) ->
    data = e.added

    providers = _.where locations, {city: data.id, country: data.country}
    clearData($provider)

    $provider.select2
      placeholder: 'Select a provider'
      data: ->
        return {results: providers, text: 'provider'}

      formatResult: providerFormat
      formatSelection:  providerFormat
    .select2 'enable', true
    .on 'change', (e) ->
      $locationField.val(e.added.id)
      setSummary(e.added)
      selectRowOnDataTable(e.added)
  .select2 'enable', false

  $provider.select2
    placeholder: 'Select a provider'
    data:
      results: locations
      text:    'provider'

    formatResult:     providerFormat
    formatSelection:  providerFormat

  .select2 'enable', false

  gb_to_tb = (value) ->
    if value >= 1000
      return "#{(value / 1000.0)} TB"
    else
      return "#{value} GB"

  setSummary = (location) ->
    hideSummary()

    if location? && !location.budget_vps
      $("#cloud-location-prices").find('.price-memory').html formatCurrency(location.prices.price_memory)
      $("#cloud-location-prices").find('.price-cpu').html formatCurrency(location.prices.price_cpu)
      $("#cloud-location-prices").find('.price-disk').html formatCurrency(location.prices.price_disk)
      $("#cloud-location-prices").find('.inclusive-bw').html gb_to_tb(location.inclusive_bandwidth)
      $("#cloud-location-prices").removeClass('hide')
    else if location? && location.budget_vps
      $("#budget-location-prices").removeClass('hide')

  hideSummary = ->
    $("#cloud-location-prices").addClass('hide')
    $("#budget-location-prices").addClass('hide')

  setCountry = (location) ->
    if location?
      $country.val location.country
      $country.select2 'enable', true
      $country.trigger jQuery.Event('change', added: location)
      return 

  setCity = (location) ->
    if location?
      $city.val location.city
      $city.select2 'enable', true
      $city.trigger jQuery.Event('change', added: {id: location.city, country: location.country})
      return

  setProvider = (location) ->
    if location?
      $provider.val location.id
      $provider.select2 'enable', true
      $provider.trigger jQuery.Event('change', added: location)
      showPackages(location)

  assignValues = (location) ->
    if location?
      setSummary(location)
      setCountry(location)
      setCity(location)
      setProvider(location)

  checkLocationValue = ->
    # Parse the return value into an integer, currently assigned as a string in the db
    fieldValue  = $locationField.val()

    unless fieldValue.length < 1
      val = parseInt(fieldValue)
      selectedLocation = _.findWhere locations, id: val
      assignValues(selectedLocation)

  showPackages = (location) ->
    $.ajax 
      type: "GET",
      url: "/servers/create/location_packages?location_id=#{location.id}",
      success: (response) ->
        $("#jg-location-packages").html(response)
        _.each $("#jg-location-packages .price"), (element) ->
          price = parseFloat $(element).html()
          $(element).html(formatCurrency(price))

        _.each $("#jg-location-packages .price-2"), (element) ->
          price = parseFloat $(element).html()
          $(element).html(formatCurrency(price, 2))

  checkLocationValue()

  setupMapBeta()

  $("#step-wizard-list").find('.index').tooltip()

  server_wizard_next_step_button = "#server_wizard_next_step"
  $("#new_server_wizard").submit (event) ->
    $(server_wizard_next_step_button).text("Please wait...")
    $(server_wizard_next_step_button).attr('disabled', 'disabled')

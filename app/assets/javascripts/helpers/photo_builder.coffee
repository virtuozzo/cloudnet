class helpers.PhotoBuilder
  defaultPhoto: "61344979"

  constructor: (properties, @marker) ->
    @ids = properties.photoIds
    @city = properties.city

  grabPhotoId: ->
    if @ids == null || @ids.split(',').length == 0
      @defaultPhoto
    else
      idsAr = @ids.split(',')
      idsAr[Math.floor(Math.random()*idsAr.length)];
    
  fetchPhoto: ->
    deferred = Q.defer()
    _500px.api "/photos/#{@grabPhotoId()}", (response) =>
      if response.err?
        console.log 'error'
        deferred.reject(response.err)
      deferred.resolve(city: @city, data: @cityPhotoObject(response.data.photo), marker: @marker)
    return deferred.promise
    
  cityPhotoObject: (obj) ->
    user:   obj?.user
    photo:  obj
    first:
      url:  "http:://500px.com/" + obj?.url
      img:
        """
          <img src="#{obj?.image_url}" width="340" height ="240"/>
        """
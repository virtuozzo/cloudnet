class helpers.PhotoBuilder
  defaultPhoto: "61344979"

  constructor: (properties) ->
    @ids = properties.photoIds
    @city = properties.city

  grabPhotoId: ->
    if @ids == null || @ids.split(',').length == 0
      @defaultPhoto
    else
      idsAr = @ids.split(',')
      idsAr[Math.floor(Math.random()*idsAr.length)]
    
  fetchPhoto: ->
    deferred = Q.defer()
    _500px.api "/photos/#{@grabPhotoId()}", (response) =>
      if response.error
        console.log response.error_message
        deferred.reject(response.err)
      deferred.resolve(city: @city, data: @cityPhotoObject(response.data.photo))
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
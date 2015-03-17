describe "Controller: ServerSearchCtrl", ->
  beforeEach ->
    loadFixtures 'server.html'
    module 'CloudNet'
    inject ($controller) ->
      console.log $controller('ServerSearchCtrl')

      
  it "should", ->
    expect(1).toEqual 1
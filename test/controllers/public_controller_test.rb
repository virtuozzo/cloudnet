require 'test_helper'

class PublicControllerTest < ActionController::TestCase
  test "should get main" do
    get :main
    assert_response :success
  end

  test "should get about_us" do
    get :about_us
    assert_response :success
  end

  test "should get howitworks" do
    get :howitworks
    assert_response :success
  end
                          
end

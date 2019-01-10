require 'test_helper'

class BaseSeriesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get base_series_show_url
    assert_response :success
  end

end

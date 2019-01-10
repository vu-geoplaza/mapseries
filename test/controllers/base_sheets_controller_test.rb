require 'test_helper'

class BaseSheetsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get base_sheets_index_url
    assert_response :success
  end

end

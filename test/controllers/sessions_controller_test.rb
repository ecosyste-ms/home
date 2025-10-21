require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'login page is accessible without authentication' do
    get login_path
    assert_response :success
  end

  test 'logout redirects to root' do
    account = create(:account)
    login_as(account)

    delete logout_path
    assert_redirected_to root_path
  end
end

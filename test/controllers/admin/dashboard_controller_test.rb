require 'test_helper'

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create(:account, admin: true)
    @regular_user = create(:account, admin: false)
  end

  test 'admin can access dashboard' do
    login_as(@admin)
    get admin_root_path
    assert_response :success
  end

  test 'non-admin cannot access dashboard' do
    login_as(@regular_user)
    get admin_root_path
    assert_redirected_to root_path
    assert_equal 'Access denied. Admin privileges required.', flash[:alert]
  end

  test 'unauthenticated user redirected to login' do
    get admin_root_path
    assert_redirected_to login_path
  end
end

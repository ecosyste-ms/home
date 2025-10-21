require 'test_helper'

class Admin::AccountsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create(:account, admin: true)
    @regular_user = create(:account, admin: false)
    @target_account = create(:account)
  end

  test 'admin can view accounts index' do
    login_as(@admin)
    get admin_accounts_path
    assert_response :success
  end

  test 'admin can view account details' do
    login_as(@admin)
    get admin_account_path(@target_account)
    assert_response :success
  end

  test 'admin can suspend account' do
    login_as(@admin)
    post suspend_admin_account_path(@target_account)
    assert_redirected_to admin_account_path(@target_account)
    assert_equal 'suspended', @target_account.reload.status
  end

  test 'admin can impersonate account' do
    login_as(@admin)
    post impersonate_admin_account_path(@target_account)
    assert_redirected_to account_path
  end

  test 'non-admin cannot access accounts index' do
    login_as(@regular_user)
    get admin_accounts_path
    assert_redirected_to root_path
    assert_equal 'Access denied. Admin privileges required.', flash[:alert]
  end

  test 'non-admin cannot suspend accounts' do
    login_as(@regular_user)
    post suspend_admin_account_path(@target_account)
    assert_redirected_to root_path
  end
end

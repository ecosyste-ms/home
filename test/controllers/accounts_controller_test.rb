require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @plan = create(:plan)
    @account = create(:account)
    @subscription = @account.subscriptions.create!(
      plan: @plan,
      status: 'active',
      current_period_start: Time.current,
      current_period_end: 1.month.from_now
    )
  end

  test 'renders account overview page' do
    login_as(@account)
    get account_path
    assert_response :success
    assert_template 'accounts/show'
    assert_select 'h1', 'Overview'
  end

  test 'overview page shows account details' do
    login_as(@account)
    get account_path
    assert_response :success
    assert_select 'p', text: /#{Regexp.escape(@account.name)}/
    assert_select 'p', text: /#{Regexp.escape(@account.email)}/
  end

  test 'overview page shows plan information' do
    login_as(@account)
    get account_path
    assert_response :success
    assert_select 'h3', 'Pro'
    assert_select 'p', text: /5,000 requests/
    assert_select 'p', text: /\$200/
  end

  test 'renders details page' do
    login_as(@account)
    get details_account_path
    assert_response :success
    assert_template 'accounts/details'
    assert_select 'h1', 'Your details'
    assert_select 'input[name="account[name]"]'
    assert_select 'input[name="account[email]"]'
  end

  test 'renders plan page' do
    login_as(@account)
    get plan_account_path
    assert_response :success
    assert_template 'accounts/plan'
    assert_select 'h1', 'Plan'
  end

  test 'renders api key page' do
    login_as(@account)
    get api_key_account_path
    assert_response :success
    assert_select 'h1'
  end

  test 'api key page shows empty state' do
    login_as(@account)
    get api_key_account_path
    assert_response :success
    assert_select 'p', text: /don't have any API keys yet/
  end

  test 'renders billing page' do
    login_as(@account)
    get billing_account_path
    assert_response :success
    assert_template 'accounts/billing'
    assert_select 'h1', 'Billing'
    assert_select 'h2.h4', 'Payment method'
  end

  test 'billing page shows empty billing history' do
    login_as(@account)
    get billing_account_path
    assert_response :success
    assert_select 'p', text: /No billing history yet/
  end

  test 'renders security page' do
    login_as(@account)
    get security_account_path
    assert_response :success
    assert_template 'accounts/security'
    assert_select 'h1', 'Password and security'
    assert_select 'h2', 'Linked accounts'
  end

  test 'security page shows connect buttons when no identities' do
    login_as(@account)
    get security_account_path
    assert_response :success
    assert_select 'button', text: /Connect GitHub/
  end

  test 'all pages include navigation' do
    login_as(@account)
    pages = [
      account_path,
      details_account_path,
      plan_account_path,
      api_key_account_path,
      billing_account_path,
      security_account_path
    ]

    pages.each do |page|
      get page
      assert_response :success
      assert_select 'ul.dboard-nav'
      assert_select 'a', text: 'Overview'
      assert_select 'a', text: 'Your details'
      assert_select 'a', text: 'Plan'
      assert_select 'a', text: 'API Key'
      assert_select 'a', text: 'Billing'
      assert_select 'a', text: 'Password and security'
    end
  end

  test 'all pages include header with account name' do
    login_as(@account)
    pages = [account_path, details_account_path, plan_account_path]

    pages.each do |page|
      get page
      assert_response :success
      assert_select 'h1.display-1', @account.name
    end
  end

  test 'redirects to login when not authenticated' do
    get account_path
    assert_redirected_to login_path
    assert_equal 'You must be logged in to access this page.', flash[:alert]
  end

  test 'all account pages redirect when not authenticated' do
    pages = [
      account_path,
      details_account_path,
      plan_account_path,
      api_key_account_path,
      billing_account_path,
      security_account_path
    ]

    pages.each do |page|
      get page
      assert_redirected_to login_path
    end
  end
end

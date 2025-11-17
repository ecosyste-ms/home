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
    assert_select 'h2', text: /Linked accounts|Manage connected accounts|Your connected account/
  end

  test 'security page shows connect buttons when no identities' do
    login_as(@account)
    get security_account_path
    assert_response :success
    assert_select 'button', text: /Connect GitHub/
  end

  test 'updates payment method' do
    login_as(@account)
    @account.update(stripe_customer_id: 'cus_123')

    stripe_service = mock('stripe_service')
    stripe_service.expects(:update_payment_method).with('pm_123')

    StripeService.expects(:new).with(@account).returns(stripe_service)

    post update_payment_method_account_path, params: { payment_method_id: 'pm_123' }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
  end

  test 'handles payment method update errors' do
    login_as(@account)
    @account.update(stripe_customer_id: 'cus_123')

    stripe_service = mock('stripe_service')
    stripe_service.expects(:update_payment_method).raises(StripeService::StripeError.new('Card declined'))

    StripeService.expects(:new).with(@account).returns(stripe_service)

    post update_payment_method_account_path, params: { payment_method_id: 'pm_123' }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal 'Card declined', json['error']
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

  test 'create_api_key creates API key and syncs to APISIX' do
    login_as(@account)

    service_mock = mock('apisix_service')
    service_mock.expects(:create_consumer).returns('test_consumer_id')
    ApisixStubService.expects(:new).returns(service_mock)

    assert_difference '@account.api_keys.count', 1 do
      post create_api_key_account_path, params: { name: 'My API Key' }
    end

    assert_redirected_to api_key_account_path
    assert_not_nil flash[:new_api_key]
    assert_match(/^[a-zA-Z0-9]{32}$/, flash[:new_api_key])

    api_key = @account.api_keys.last
    assert_equal 'My API Key', api_key.name
    assert_equal 'test_consumer_id', api_key.apisix_consumer_id
  end

  test 'create_api_key auto-generates name if not provided' do
    login_as(@account)

    service_mock = mock('apisix_service')
    service_mock.expects(:create_consumer).returns('test_consumer_id')
    ApisixStubService.expects(:new).returns(service_mock)

    post create_api_key_account_path
    assert_redirected_to api_key_account_path

    api_key = @account.api_keys.last
    assert_match(/API Key \d+/, api_key.name)
  end

  test 'create_api_key fails when APISIX is unreachable' do
    login_as(@account)

    service_mock = mock('apisix_service')
    service_mock.expects(:create_consumer).raises(ApisixStubService::ConnectionError.new('Failed to connect'))
    ApisixStubService.expects(:new).returns(service_mock)

    assert_no_difference '@account.api_keys.count' do
      post create_api_key_account_path, params: { name: 'My API Key' }
    end

    assert_redirected_to api_key_account_path
    assert_match(/Failed to create API key/, flash[:alert])
  end

  test 'create_api_key fails when APISIX returns error' do
    login_as(@account)

    service_mock = mock('apisix_service')
    service_mock.expects(:create_consumer).raises(ApisixStubService::ApiError.new('Internal error'))
    ApisixStubService.expects(:new).returns(service_mock)

    assert_no_difference '@account.api_keys.count' do
      post create_api_key_account_path, params: { name: 'My API Key' }
    end

    assert_redirected_to api_key_account_path
    assert_match(/Failed to create API key/, flash[:alert])
  end

  test 'revoke_api_key revokes key and deletes from APISIX' do
    login_as(@account)

    # Create a valid API key
    api_key = @account.api_keys.build(name: 'Test Key')
    api_key.send(:generate_key)
    api_key.apisix_consumer_id = 'test_prefix'
    api_key.save!

    service_mock = mock('apisix_service')
    service_mock.expects(:delete_consumer).with(consumer_name: 'test_prefix').returns(true)
    ApisixStubService.expects(:new).returns(service_mock)

    delete revoke_api_key_account_path(api_key_id: api_key.id)

    assert_redirected_to api_key_account_path
    assert_match(/API Key has been revoked/, flash[:notice])

    api_key.reload
    assert api_key.revoked?
  end

  test 'revoke_api_key handles keys without APISIX consumer ID' do
    login_as(@account)

    # Create a valid API key without consumer ID
    api_key = @account.api_keys.build(name: 'Test Key')
    api_key.send(:generate_key)
    api_key.save!

    # Should not call APISIX service
    ApisixService.expects(:new).never

    delete revoke_api_key_account_path(api_key_id: api_key.id)

    assert_redirected_to api_key_account_path
    assert_match(/API Key has been revoked/, flash[:notice])

    api_key.reload
    assert api_key.revoked?
  end

  test 'revoke_api_key fails when APISIX delete fails' do
    login_as(@account)

    # Create a valid API key
    api_key = @account.api_keys.build(name: 'Test Key')
    api_key.send(:generate_key)
    api_key.apisix_consumer_id = 'test_prefix'
    api_key.save!

    service_mock = mock('apisix_service')
    service_mock.expects(:delete_consumer).raises(ApisixStubService::ApiError.new('Internal error'))
    ApisixStubService.expects(:new).returns(service_mock)

    delete revoke_api_key_account_path(api_key_id: api_key.id)

    assert_redirected_to api_key_account_path
    assert_match(/Failed to revoke API key/, flash[:alert])

    api_key.reload
    assert_not api_key.revoked?
  end
end

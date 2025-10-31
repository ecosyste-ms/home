require 'test_helper'

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  def setup
    @account = create(:account)
    @plan = create(:plan, stripe_price_id: 'price_123', price_cents: 1000)
  end

  test 'new requires authentication' do
    get checkout_path(@plan)
    assert_redirected_to login_path
  end

  test 'new renders checkout page' do
    login_as(@account)
    get checkout_path(@plan)
    assert_response :success
    assert_template 'checkout/new'
    assert_select 'h1', text: /Complete your order/
  end

  test 'new redirects if already on plan' do
    subscription = create(:subscription, account: @account, plan: @plan)
    login_as(@account)

    get checkout_path(@plan)
    assert_redirected_to plan_account_path
  end

  test 'new redirects if plan not found' do
    login_as(@account)

    get checkout_path(plan_id: 99999)
    assert_redirected_to plan_account_path
  end

  test 'create successfully creates subscription' do
    login_as(@account)

    stripe_service = mock('stripe_service')
    subscription = create(:subscription, account: @account, plan: @plan)
    stripe_service.expects(:create_subscription).returns({
      subscription: subscription,
      client_secret: nil
    })

    StripeService.expects(:new).with(@account).returns(stripe_service)

    post create_checkout_path(@plan), params: { payment_method_id: 'pm_123' }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
    assert_equal billing_account_path, json['redirect_url']
  end

  test 'create returns client_secret when payment requires action' do
    login_as(@account)

    stripe_service = mock('stripe_service')
    subscription = create(:subscription, account: @account, plan: @plan)
    stripe_service.expects(:create_subscription).returns({
      subscription: subscription,
      client_secret: 'pi_secret_123'
    })

    StripeService.expects(:new).with(@account).returns(stripe_service)

    post create_checkout_path(@plan), params: { payment_method_id: 'pm_123' }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json['requires_action']
    assert_equal 'pi_secret_123', json['client_secret']
  end

  test 'create handles stripe errors' do
    login_as(@account)

    stripe_service = mock('stripe_service')
    stripe_service.expects(:create_subscription).raises(StripeService::StripeError.new('Card declined'))

    StripeService.expects(:new).with(@account).returns(stripe_service)

    post create_checkout_path(@plan), params: { payment_method_id: 'pm_123' }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal 'Card declined', json['error']
  end
end

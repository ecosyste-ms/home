require 'test_helper'

class StripeServiceTest < ActiveSupport::TestCase
  def setup
    @account = create(:account)
    @plan = create(:plan, stripe_price_id: 'price_123')
    @service = StripeService.new(@account)
  end

  test 'create_or_retrieve_customer creates new customer if none exists' do
    customer = mock('customer')
    customer.stubs(:id).returns('cus_123')

    Stripe::Customer.expects(:create).with(
      email: @account.email,
      name: @account.name,
      metadata: { account_id: @account.id }
    ).returns(customer)

    result = @service.create_or_retrieve_customer

    assert_equal customer, result
    assert_equal 'cus_123', @account.reload.stripe_customer_id
  end

  test 'create_or_retrieve_customer retrieves existing customer' do
    @account.update(stripe_customer_id: 'cus_123')
    customer = mock('customer')

    Stripe::Customer.expects(:retrieve).with('cus_123').returns(customer)

    result = @service.create_or_retrieve_customer

    assert_equal customer, result
  end

  test 'create_or_retrieve_customer creates new customer if existing one is not found' do
    @account.update(stripe_customer_id: 'cus_invalid')

    Stripe::Customer.expects(:retrieve).with('cus_invalid').raises(Stripe::InvalidRequestError.new('message', 'param'))

    customer = mock('customer')
    customer.stubs(:id).returns('cus_new')

    Stripe::Customer.expects(:create).returns(customer)

    result = @service.create_or_retrieve_customer

    assert_equal customer, result
    assert_equal 'cus_new', @account.reload.stripe_customer_id
  end

  test 'create_subscription creates subscription with payment method' do
    customer = mock('customer')
    customer.stubs(:id).returns('cus_123')

    payment_method = mock('payment_method')
    payment_method.stubs(:id).returns('pm_123')
    payment_method.stubs(:type).returns('card')
    card = mock('card')
    card.stubs(:brand).returns('visa')
    card.stubs(:last4).returns('4242')
    card.stubs(:exp_month).returns(12)
    card.stubs(:exp_year).returns(2025)
    payment_method.stubs(:card).returns(card)

    # Mock subscription with items structure (Stripe API 2025+)
    item = mock('subscription_item')
    item.stubs(:current_period_start).returns(Time.current.to_i)
    item.stubs(:current_period_end).returns(1.month.from_now.to_i)

    items = mock('items')
    items.stubs(:data).returns([item])

    subscription = mock('subscription')
    subscription.stubs(:id).returns('sub_123')
    subscription.stubs(:status).returns('active')
    subscription.stubs(:items).returns(items)
    subscription.stubs(:cancel_at_period_end).returns(false)
    subscription.stubs(:latest_invoice).returns(nil)

    @service.stubs(:create_or_retrieve_customer).returns(customer)
    Stripe::PaymentMethod.expects(:attach).with('pm_123', { customer: 'cus_123' }).returns(payment_method)
    Stripe::Customer.expects(:update).with('cus_123', invoice_settings: { default_payment_method: 'pm_123' })
    Stripe::Subscription.expects(:create).returns(subscription)

    result = @service.create_subscription(plan: @plan, payment_method_id: 'pm_123')

    assert result[:subscription].persisted?
    assert_equal 'sub_123', result[:subscription].stripe_subscription_id
    assert_equal 'Visa', @account.reload.payment_method_type
    assert_equal '4242', @account.payment_method_last4
  end

  test 'create_subscription raises error if plan has no stripe_price_id' do
    plan = create(:plan, stripe_price_id: nil)

    assert_raises(StripeService::StripeError) do
      @service.create_subscription(plan: plan, payment_method_id: 'pm_123')
    end
  end

  test 'create_subscription handles incomplete status without period dates' do
    customer = mock('customer')
    customer.stubs(:id).returns('cus_123')

    payment_method = mock('payment_method')
    payment_method.stubs(:id).returns('pm_123')
    payment_method.stubs(:type).returns('card')
    card = mock('card')
    card.stubs(:brand).returns('visa')
    card.stubs(:last4).returns('4242')
    card.stubs(:exp_month).returns(12)
    card.stubs(:exp_year).returns(2025)
    payment_method.stubs(:card).returns(card)

    # Mock subscription with items but no period dates (incomplete status)
    item = mock('subscription_item')
    item.stubs(:current_period_start).returns(nil)
    item.stubs(:current_period_end).returns(nil)

    items = mock('items')
    items.stubs(:data).returns([item])

    subscription = mock('subscription')
    subscription.stubs(:id).returns('sub_123')
    subscription.stubs(:status).returns('incomplete')
    subscription.stubs(:items).returns(items)
    subscription.stubs(:cancel_at_period_end).returns(false)
    subscription.stubs(:latest_invoice).returns(nil)

    @service.stubs(:create_or_retrieve_customer).returns(customer)
    Stripe::PaymentMethod.expects(:attach).with('pm_123', { customer: 'cus_123' }).returns(payment_method)
    Stripe::Customer.expects(:update).with('cus_123', invoice_settings: { default_payment_method: 'pm_123' })
    Stripe::Subscription.expects(:create).returns(subscription)

    result = @service.create_subscription(plan: @plan, payment_method_id: 'pm_123')

    assert result[:subscription].persisted?
    assert_equal 'sub_123', result[:subscription].stripe_subscription_id
    assert_equal 'incomplete', result[:subscription].status
    assert_nil result[:subscription].current_period_start
    assert_nil result[:subscription].current_period_end
  end

  test 'cancel_subscription cancels at period end by default' do
    subscription = create(:subscription, account: @account, stripe_subscription_id: 'sub_123')
    stripe_subscription = mock('stripe_subscription')

    Stripe::Subscription.expects(:update).with('sub_123', cancel_at_period_end: true).returns(stripe_subscription)

    @service.cancel_subscription(subscription)

    assert subscription.reload.cancel_at_period_end?
  end

  test 'cancel_subscription cancels immediately when specified' do
    subscription = create(:subscription, account: @account, stripe_subscription_id: 'sub_123')
    stripe_subscription = mock('stripe_subscription')

    Stripe::Subscription.expects(:cancel).with('sub_123').returns(stripe_subscription)

    @service.cancel_subscription(subscription, immediately: true)

    assert_equal 'canceled', subscription.reload.status
  end

  test 'retrieve_payment_method returns nil if no stripe customer' do
    @account.update(stripe_customer_id: nil)

    result = @service.retrieve_payment_method

    assert_nil result
  end

  test 'retrieve_payment_method fetches payment method from stripe' do
    @account.update(stripe_customer_id: 'cus_123')

    payment_method = mock('payment_method')
    invoice_settings = mock('invoice_settings')
    invoice_settings.stubs(:default_payment_method).returns(payment_method)

    customer = mock('customer')
    customer.stubs(:invoice_settings).returns(invoice_settings)

    Stripe::Customer.expects(:retrieve).with('cus_123', { expand: ['invoice_settings.default_payment_method'] }).returns(customer)

    result = @service.retrieve_payment_method

    assert_equal payment_method, result
  end
end

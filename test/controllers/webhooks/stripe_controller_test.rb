require 'test_helper'

module Webhooks
  class StripeControllerTest < ActionDispatch::IntegrationTest
    def setup
      @account = create(:account, stripe_customer_id: 'cus_123')
      @plan = create(:plan, stripe_price_id: 'price_123')
      @subscription = create(:subscription, account: @account, plan: @plan, stripe_subscription_id: 'sub_123')
    end

    test 'rejects webhooks with invalid signature' do
      payload = { type: 'customer.subscription.updated' }.to_json

      Stripe::Webhook.expects(:construct_event).raises(Stripe::SignatureVerificationError.new('message', 'sig'))

      post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }

      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal 'Invalid signature', json['error']
    end

    test 'stores all events in database' do
    # Mock Stripe API 2025+ structure with items
    item = mock('subscription_item')
    item.stubs(:current_period_start).returns(Time.current.to_i)
    item.stubs(:current_period_end).returns(1.month.from_now.to_i)

    items = mock('items')
    items.stubs(:data).returns([item])

    stripe_subscription = mock('subscription')
    stripe_subscription.stubs(:id).returns('sub_123')
    stripe_subscription.stubs(:status).returns('active')
    stripe_subscription.stubs(:items).returns(items)
    stripe_subscription.stubs(:cancel_at_period_end).returns(false)

    event_data = mock('event_data')
    event_data.stubs(:object).returns(stripe_subscription)

    event = mock('event')
    event.stubs(:id).returns('evt_test_123')
    event.stubs(:type).returns('customer.subscription.updated')
    event.stubs(:data).returns(event_data)
    event.stubs(:to_hash).returns({ 'id' => 'evt_test_123', 'type' => 'customer.subscription.updated' })

    Stripe::Webhook.expects(:construct_event).returns(event)

    assert_difference 'StripeEvent.count', 1 do
      payload = { type: 'customer.subscription.updated' }.to_json
      post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }
    end

    assert_response :ok
    stripe_event = StripeEvent.last
    assert_equal 'evt_test_123', stripe_event.event_id
    assert_equal 'customer.subscription.updated', stripe_event.event_type
    assert_equal 'processed', stripe_event.status
    assert_not_nil stripe_event.processed_at
  end

  test 'marks event as failed when processing fails' do
    event_data = mock('event_data')
    event_data.stubs(:object).raises(StandardError.new('Test error'))

    event = mock('event')
    event.stubs(:id).returns('evt_test_fail')
    event.stubs(:type).returns('customer.subscription.updated')
    event.stubs(:data).returns(event_data)
    event.stubs(:to_hash).returns({ 'id' => 'evt_test_fail', 'type' => 'customer.subscription.updated' })

    Stripe::Webhook.expects(:construct_event).returns(event)

    assert_difference 'StripeEvent.count', 1 do
      payload = { type: 'customer.subscription.updated' }.to_json
      post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }
    end

    assert_response :ok  # Still returns 200 so Stripe doesn't retry
    stripe_event = StripeEvent.last
    assert_equal 'failed', stripe_event.status
    assert_not_nil stripe_event.error_message
    assert_includes stripe_event.error_message, 'Test error'
  end

  test 'does not create duplicate events' do
    stripe_subscription = mock('subscription')
    stripe_subscription.stubs(:id).returns('sub_123')
    stripe_subscription.stubs(:status).returns('active')
    stripe_subscription.stubs(:current_period_start).returns(Time.current.to_i)
    stripe_subscription.stubs(:current_period_end).returns(1.month.from_now.to_i)
    stripe_subscription.stubs(:cancel_at_period_end).returns(false)

    event_data = mock('event_data')
    event_data.stubs(:object).returns(stripe_subscription)

    event = mock('event')
    event.stubs(:id).returns('evt_duplicate')
    event.stubs(:type).returns('customer.subscription.updated')
    event.stubs(:data).returns(event_data)
    event.stubs(:to_hash).returns({ 'id' => 'evt_duplicate', 'type' => 'customer.subscription.updated' })

    Stripe::Webhook.expects(:construct_event).twice.returns(event)

    # First webhook
    assert_difference 'StripeEvent.count', 1 do
      payload = { type: 'customer.subscription.updated' }.to_json
      post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }
    end

    # Same webhook again (Stripe retry)
    assert_no_difference 'StripeEvent.count' do
      payload = { type: 'customer.subscription.updated' }.to_json
      post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }
    end
  end

  test 'handles customer.subscription.updated event' do
      # Mock Stripe API 2025+ structure with items
      item = mock('subscription_item')
      item.stubs(:current_period_start).returns(Time.current.to_i)
      item.stubs(:current_period_end).returns(1.month.from_now.to_i)

      items = mock('items')
      items.stubs(:data).returns([item])

      stripe_subscription = mock('subscription')
      stripe_subscription.stubs(:id).returns('sub_123')
      stripe_subscription.stubs(:status).returns('active')
      stripe_subscription.stubs(:items).returns(items)
      stripe_subscription.stubs(:cancel_at_period_end).returns(false)

      event_data = mock('event_data')
      event_data.stubs(:object).returns(stripe_subscription)

      event = mock('event')
      event.stubs(:id).returns('evt_updated_123')
      event.stubs(:type).returns('customer.subscription.updated')
      event.stubs(:data).returns(event_data)
      event.stubs(:to_hash).returns({ 'id' => 'evt_updated_123', 'type' => 'customer.subscription.updated' })

      Stripe::Webhook.expects(:construct_event).returns(event)

      payload = { type: 'customer.subscription.updated' }.to_json
      post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }

      assert_response :ok
    end

    test 'handles customer.subscription.deleted event' do
      stripe_subscription = mock('subscription')
      stripe_subscription.stubs(:id).returns('sub_123')
      stripe_subscription.stubs(:ended_at).returns(Time.current.to_i)

      event_data = mock('event_data')
      event_data.stubs(:object).returns(stripe_subscription)

      event = mock('event')
      event.stubs(:id).returns('evt_deleted_123')
      event.stubs(:type).returns('customer.subscription.deleted')
      event.stubs(:data).returns(event_data)
      event.stubs(:to_hash).returns({ 'id' => 'evt_deleted_123', 'type' => 'customer.subscription.deleted' })

      Stripe::Webhook.expects(:construct_event).returns(event)

      payload = { type: 'customer.subscription.deleted' }.to_json
      post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }

      assert_response :ok
      assert_equal 'canceled', @subscription.reload.status
    end

    test 'handles invoice.payment_succeeded event' do
      stripe_invoice = mock('invoice')
      stripe_invoice.stubs(:id).returns('in_123')
      stripe_invoice.stubs(:customer).returns('cus_123')
      stripe_invoice.stubs(:subscription).returns('sub_123')
      stripe_invoice.stubs(:number).returns('INV-001')
      stripe_invoice.stubs(:amount_due).returns(1000)
      stripe_invoice.stubs(:amount_paid).returns(1000)
      stripe_invoice.stubs(:currency).returns('usd')
      stripe_invoice.stubs(:period_start).returns(Time.current.to_i)
      stripe_invoice.stubs(:period_end).returns(1.month.from_now.to_i)
      stripe_invoice.stubs(:hosted_invoice_url).returns('https://invoice.stripe.com/i/123')
      stripe_invoice.stubs(:invoice_pdf).returns('https://invoice.stripe.com/i/123/pdf')

      status_transitions = mock('status_transitions')
      status_transitions.stubs(:paid_at).returns(Time.current.to_i)
      stripe_invoice.stubs(:status_transitions).returns(status_transitions)

      event_data = mock('event_data')
      event_data.stubs(:object).returns(stripe_invoice)

      event = mock('event')
      event.stubs(:id).returns('evt_invoice_paid_123')
      event.stubs(:type).returns('invoice.payment_succeeded')
      event.stubs(:data).returns(event_data)
      event.stubs(:to_hash).returns({ 'id' => 'evt_invoice_paid_123', 'type' => 'invoice.payment_succeeded' })

      Stripe::Webhook.expects(:construct_event).returns(event)

      assert_difference '@account.invoices.count', 1 do
        payload = { type: 'invoice.payment_succeeded' }.to_json
        post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }
      end

      assert_response :ok
      invoice = @account.invoices.last
      assert_equal 'paid', invoice.status
      assert_equal 1000, invoice.amount_due_cents
    end

    test 'handles invoice.payment_failed event' do
      stripe_invoice = mock('invoice')
      stripe_invoice.stubs(:id).returns('in_123')
      stripe_invoice.stubs(:customer).returns('cus_123')
      stripe_invoice.stubs(:subscription).returns('sub_123')
      stripe_invoice.stubs(:number).returns('INV-001')
      stripe_invoice.stubs(:amount_due).returns(1000)
      stripe_invoice.stubs(:amount_paid).returns(0)
      stripe_invoice.stubs(:currency).returns('usd')
      stripe_invoice.stubs(:period_start).returns(Time.current.to_i)
      stripe_invoice.stubs(:period_end).returns(1.month.from_now.to_i)
      stripe_invoice.stubs(:due_date).returns(1.week.from_now.to_i)
      stripe_invoice.stubs(:hosted_invoice_url).returns('https://invoice.stripe.com/i/123')
      stripe_invoice.stubs(:invoice_pdf).returns('https://invoice.stripe.com/i/123/pdf')
      stripe_invoice.stubs(:status_transitions).returns(nil)

      event_data = mock('event_data')
      event_data.stubs(:object).returns(stripe_invoice)

      event = mock('event')
      event.stubs(:id).returns('evt_invoice_failed_123')
      event.stubs(:type).returns('invoice.payment_failed')
      event.stubs(:data).returns(event_data)
      event.stubs(:to_hash).returns({ 'id' => 'evt_invoice_failed_123', 'type' => 'invoice.payment_failed' })

      Stripe::Webhook.expects(:construct_event).returns(event)

      assert_difference '@account.invoices.count', 1 do
        payload = { type: 'invoice.payment_failed' }.to_json
        post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }
      end

      assert_response :ok
      invoice = @account.invoices.last
      assert_equal 'open', invoice.status
    end

    test 'handles unrecognized event types gracefully' do
      event = mock('event')
      event.stubs(:id).returns('evt_unknown_123')
      event.stubs(:type).returns('unknown.event.type')
      event.stubs(:to_hash).returns({ 'id' => 'evt_unknown_123', 'type' => 'unknown.event.type' })

      Stripe::Webhook.expects(:construct_event).returns(event)

      payload = { type: 'unknown.event.type' }.to_json
      post '/webhooks/stripe', params: payload, headers: { 'Content-Type' => 'application/json' }

      assert_response :ok
    end
  end
end

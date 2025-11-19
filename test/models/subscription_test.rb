require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  def setup
    @account = create(:account)
    @plan = create(:plan)
    @subscription = create(:subscription, account: @account, plan: @plan)
  end

  test 'sync_from_stripe updates subscription fields' do
    # Mock Stripe API 2025+ structure with items
    item = mock('subscription_item')
    item.stubs(:current_period_start).returns(Time.current.to_i)
    item.stubs(:current_period_end).returns(1.month.from_now.to_i)

    items = mock('items')
    items.stubs(:data).returns([item])

    stripe_subscription = mock('stripe_subscription')
    stripe_subscription.stubs(:status).returns('active')
    stripe_subscription.stubs(:items).returns(items)
    stripe_subscription.stubs(:cancel_at_period_end).returns(false)

    @subscription.sync_from_stripe(stripe_subscription)

    assert_equal 'active', @subscription.status
    assert_not_nil @subscription.current_period_start
    assert_not_nil @subscription.current_period_end
    assert_equal false, @subscription.cancel_at_period_end
  end

  test 'sync_from_stripe handles nil period dates' do
    # Mock Stripe API 2025+ structure with items but no period dates
    item = mock('subscription_item')
    item.stubs(:current_period_start).returns(nil)
    item.stubs(:current_period_end).returns(nil)

    items = mock('items')
    items.stubs(:data).returns([item])

    stripe_subscription = mock('stripe_subscription')
    stripe_subscription.stubs(:status).returns('incomplete')
    stripe_subscription.stubs(:items).returns(items)
    stripe_subscription.stubs(:cancel_at_period_end).returns(false)

    @subscription.sync_from_stripe(stripe_subscription)

    assert_equal 'incomplete', @subscription.status
    assert_nil @subscription.current_period_start
    assert_nil @subscription.current_period_end
  end
end

require 'test_helper'
require 'rake'

class StripeRakeTest < ActiveSupport::TestCase
  def setup
    Rails.application.load_tasks unless Rake::Task.task_defined?('stripe:update_prices')
  end

  test 'update_prices creates new price and archives old when price_cents differs' do
    plan = create(:plan,
      name: 'Test Plan',
      price_cents: 5000,
      billing_period: 'month',
      stripe_price_id: 'price_old_123'
    )

    old_stripe_price = mock('old_stripe_price')
    old_stripe_price.stubs(:id).returns('price_old_123')
    old_stripe_price.stubs(:unit_amount).returns(3000)
    old_stripe_price.stubs(:product).returns('prod_123')

    new_stripe_price = mock('new_stripe_price')
    new_stripe_price.stubs(:id).returns('price_new_456')

    Stripe::Price.expects(:retrieve).with('price_old_123').returns(old_stripe_price)
    Stripe::Price.expects(:create).with(
      product: 'prod_123',
      unit_amount: 5000,
      currency: 'usd',
      recurring: { interval: 'month' }
    ).returns(new_stripe_price)
    Stripe::Price.expects(:update).with('price_old_123', active: false)

    Rake::Task['stripe:update_prices'].reenable
    Rake::Task['stripe:update_prices'].invoke

    assert_equal 'price_new_456', plan.reload.stripe_price_id
  end

  test 'update_prices skips plan when price_cents matches stripe' do
    plan = create(:plan,
      name: 'Matching Plan',
      price_cents: 5000,
      billing_period: 'month',
      stripe_price_id: 'price_matching'
    )

    stripe_price = mock('stripe_price')
    stripe_price.stubs(:unit_amount).returns(5000)

    Stripe::Price.expects(:retrieve).with('price_matching').returns(stripe_price)
    Stripe::Price.expects(:create).never
    Stripe::Price.expects(:update).never

    Rake::Task['stripe:update_prices'].reenable
    Rake::Task['stripe:update_prices'].invoke

    assert_equal 'price_matching', plan.reload.stripe_price_id
  end

  test 'update_prices skips free plans' do
    plan = create(:plan,
      name: 'Free Plan',
      price_cents: 0,
      billing_period: 'month',
      stripe_price_id: 'price_free'
    )

    Stripe::Price.expects(:retrieve).never

    Rake::Task['stripe:update_prices'].reenable
    Rake::Task['stripe:update_prices'].invoke

    assert_equal 'price_free', plan.reload.stripe_price_id
  end

  test 'update_prices skips plans without stripe_price_id' do
    plan = create(:plan,
      name: 'No Stripe Plan',
      price_cents: 5000,
      billing_period: 'month',
      stripe_price_id: nil
    )

    Stripe::Price.expects(:retrieve).never

    Rake::Task['stripe:update_prices'].reenable
    Rake::Task['stripe:update_prices'].invoke

    assert_nil plan.reload.stripe_price_id
  end

  test 'update_prices handles stripe errors gracefully' do
    plan = create(:plan,
      name: 'Error Plan',
      price_cents: 5000,
      billing_period: 'month',
      stripe_price_id: 'price_error'
    )

    Stripe::Price.expects(:retrieve).with('price_error').raises(Stripe::StripeError.new('API error'))

    Rake::Task['stripe:update_prices'].reenable

    assert_nothing_raised do
      Rake::Task['stripe:update_prices'].invoke
    end

    assert_equal 'price_error', plan.reload.stripe_price_id
  end
end

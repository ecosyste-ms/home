require 'test_helper'

class PlanTest < ActiveSupport::TestCase
  def setup
    Plan.find_or_create_by(name: 'Free') do |plan|
      plan.price_cents = 0
      plan.billing_period = 'month'
      plan.requests_per_hour = 300
    end

    Plan.find_or_create_by(name: 'Pro') do |plan|
      plan.price_cents = 20000
      plan.billing_period = 'month'
      plan.requests_per_hour = 5000
    end

    Plan.find_or_create_by(name: 'Enterprise') do |plan|
      plan.price_cents = 80000
      plan.billing_period = 'month'
      plan.requests_per_hour = 20000
    end
  end

  test 'creates a plan with valid attributes' do
    plan = Plan.new(
      name: 'Test Plan',
      requests_per_hour: 1000,
      price_cents: 5000,
      billing_period: 'month'
    )

    assert plan.valid?
    assert_equal 'Test Plan', plan.name
    assert_equal 1000, plan.requests_per_hour
    assert_equal 50, plan.price_dollars
  end

  test 'requires name' do
    plan = Plan.new(requests_per_hour: 1000, price_cents: 5000)
    assert_not plan.valid?
    assert_includes plan.errors[:name], "can't be blank"
  end

  test 'requires requests_per_hour' do
    plan = Plan.new(name: 'Test', price_cents: 5000, billing_period: 'month')
    assert_not plan.valid?
    assert_includes plan.errors[:requests_per_hour], "can't be blank"
  end

  test 'validates billing_period is month or year' do
    plan = Plan.new(name: 'Test', requests_per_hour: 1000, price_cents: 5000, billing_period: 'invalid')
    assert_not plan.valid?
    assert_includes plan.errors[:billing_period], 'is not included in the list'
  end

  test 'all returns list of plans from database' do
    plans = Plan.all

    assert_operator plans.length, :>=, 3
    assert_includes plans.map(&:name), 'Free'
    assert_includes plans.map(&:name), 'Pro'
    assert_includes plans.map(&:name), 'Enterprise'
  end

  test 'find_by returns correct plan' do
    plan = Plan.find_by(name: 'Pro')

    assert_not_nil plan
    assert_equal 'Pro', plan.name
    assert_equal 5000, plan.requests_per_hour
    assert_equal 200, plan.price_dollars
  end

  test 'free? returns true for free plan' do
    plan = Plan.find_by(name: 'Free')
    assert plan.free?
  end

  test 'free? returns false for paid plans' do
    plan = Plan.find_by(name: 'Pro')
    assert_not plan.free?
  end

  test 'formatted_price returns Free for free plan' do
    plan = Plan.find_by(name: 'Free')
    assert_equal 'Free', plan.formatted_price
  end

  test 'formatted_price returns dollar amount for paid plans' do
    plan = Plan.find_by(name: 'Pro')
    assert_equal '$200', plan.formatted_price
  end

  test 'formatted_requests returns formatted string' do
    plan = Plan.find_by(name: 'Pro')
    assert_equal '5,000', plan.formatted_requests
  end
end

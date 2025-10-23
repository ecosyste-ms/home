require 'test_helper'

class PlanTest < ActiveSupport::TestCase
  def setup
    # canonical three plans used across the app now
    Plan.find_or_create_by(name: 'Free') do |plan|
      plan.price_cents = 0
      plan.billing_period = 'month'
      plan.requests_per_hour = 300
    end

    Plan.find_or_create_by(name: 'Researcher') do |plan|
      plan.price_cents = 10000   # $100/mo
      plan.billing_period = 'month'
      plan.requests_per_hour = 2000
    end

    Plan.find_or_create_by(name: 'Developer') do |plan|
      plan.price_cents = 50000   # $500/mo
      plan.billing_period = 'month'
      plan.requests_per_hour = 5000
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
    names = plans.map(&:name)
    assert_includes names, 'Free'
    assert_includes names, 'Researcher'
    assert_includes names, 'Developer'
  end

  test 'find_by returns correct plan' do
    plan = Plan.find_by(name: 'Developer')

    assert_not_nil plan
    assert_equal 'Developer', plan.name
    assert_equal 5000, plan.requests_per_hour
    assert_equal 500, plan.price_dollars
  end

  test 'free? returns true for free plan' do
    plan = Plan.find_by(name: 'Free')
    assert plan.free?
  end

  test 'free? returns false for paid plans' do
    plan = Plan.find_by(name: 'Researcher')
    assert_not plan.free?
  end

  test 'formatted_price returns Free for free plan' do
    plan = Plan.find_by(name: 'Free')
    assert_equal 'Free', plan.formatted_price
  end

  test 'formatted_price returns dollar amount for paid plans' do
    plan = Plan.find_by(name: 'Researcher')
    assert_equal '$100', plan.formatted_price
  end

  test 'formatted_requests returns formatted string' do
    plan = Plan.find_by(name: 'Developer')
    assert_equal '5,000', plan.formatted_requests
  end
end
require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test 'creates an account with valid attributes' do
    account = Account.new(
      name: 'Test User',
      email: 'test@example.com',
      plan_name: 'Pro'
    )

    assert account.valid?
    assert_equal 'Test User', account.name
    assert_equal 'test@example.com', account.email
  end

  test 'requires name' do
    account = Account.new(email: 'test@example.com')
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test 'requires email' do
    account = Account.new(name: 'Test User')
    assert_not account.valid?
    assert_includes account.errors[:email], "can't be blank"
  end

  test 'validates email format' do
    account = Account.new(name: 'Test User', email: 'invalid-email')
    assert_not account.valid?
    assert_includes account.errors[:email], 'is invalid'
  end

  test 'returns profile picture url from github identity' do
    account = Account.new(name: 'Test', email: 'test@example.com')
    account.add_identity(Identity.new(provider: 'github', username: 'testuser', uid: '123'))

    assert_equal 'https://github.com/testuser.png', account.profile_picture_url
  end

  test 'returns nil profile picture url without github identity' do
    account = Account.new(name: 'Test', email: 'test@example.com')
    assert_nil account.profile_picture_url
  end

  test 'retrieves plan details from Plan model' do
    account = Account.new(name: 'Test', email: 'test@example.com', plan_name: 'Pro')

    assert_equal 5000, account.plan_requests
    assert_equal 200, account.plan_price
    assert_equal 'monthly', account.plan_billing_period
  end

  test 'handles identities collection' do
    account = Account.new(name: 'Test', email: 'test@example.com')

    identity = Identity.new(provider: 'github', username: 'test', uid: '123')
    account.add_identity(identity)

    assert_equal 1, account.identities.length
    assert_equal 'github', account.identities.first.provider
  end

  test 'current returns mock account' do
    account = Account.current

    assert_equal 'Ben Nicholls', account.name
    assert_equal 'ben@ecosyste.ms', account.email
    assert_equal 'Pro', account.plan_name
    assert_equal 1, account.identities.length
  end

  test 'billing history returns array of Billing objects' do
    account = Account.current
    history = account.billing_history

    assert_equal 9, history.length
    assert_instance_of Billing, history.first
    assert_equal account.email, history.first.account_email
    assert history.first.month.present?
    assert history.first.amount.present?
  end
end

require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  def setup
    @account = Account.create!(
      name: 'Test User',
      email: 'test@example.com'
    )
  end

  test 'valid account' do
    assert @account.valid?
    assert_equal 'Test User', @account.name
    assert_equal 'test@example.com', @account.email
  end

  test 'requires name' do
    @account.name = nil
    assert_not @account.valid?
    assert_includes @account.errors[:name], "can't be blank"
  end

  test 'requires email' do
    @account.email = nil
    assert_not @account.valid?
    assert_includes @account.errors[:email], "can't be blank"
  end

  test 'validates email format' do
    @account.email = 'invalid-email'
    assert_not @account.valid?
    assert_includes @account.errors[:email], 'is invalid'
  end

  test 'requires unique email' do
    duplicate = Account.new(
      name: 'Another User',
      email: @account.email
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], 'has already been taken'
  end

  test 'has many identities' do
    identity = @account.identities.create!(
      provider: 'github',
      uid: '12345',
      username: 'testuser'
    )
    assert_includes @account.identities, identity
  end

  test 'has many api_keys' do
    api_key = @account.api_keys.create!(
      name: 'Test Key',
      key_hash: '$2a$12$test',
      key_prefix: 'test_pre'
    )
    assert_includes @account.api_keys, api_key
  end

  test 'active scope excludes deleted accounts' do
    @account.soft_delete!
    assert_not_includes Account.active, @account
  end

  test 'soft_delete! sets deleted_at and status' do
    @account.soft_delete!
    assert_not_nil @account.deleted_at
    assert_equal 'deleted', @account.status
  end

  test 'suspend! sets suspended status' do
    @account.suspend!
    assert_equal 'suspended', @account.status
    assert_not_nil @account.suspended_at
  end

  test 'activate! sets active status' do
    @account.suspend!
    @account.activate!
    assert_equal 'active', @account.status
    assert_nil @account.suspended_at
  end

  test 'profile_picture_url from GitHub identity' do
    @account.identities.create!(
      provider: 'github',
      uid: '12345',
      username: 'testuser'
    )
    assert_equal 'https://github.com/testuser.png', @account.profile_picture_url
  end

  test 'profile_picture_url returns nil without identities' do
    assert_nil @account.profile_picture_url
  end
end

require 'test_helper'

class IdentityTest < ActiveSupport::TestCase
  test 'creates an identity with valid attributes' do
    identity = Identity.new(
      provider: 'github',
      uid: '12345',
      username: 'testuser'
    )

    assert identity.valid?
    assert_equal 'github', identity.provider
    assert_equal '12345', identity.uid
    assert_equal 'testuser', identity.username
  end

  test 'requires provider' do
    identity = Identity.new(uid: '12345')
    assert_not identity.valid?
    assert_includes identity.errors[:provider], "can't be blank"
  end

  test 'requires uid' do
    identity = Identity.new(provider: 'github')
    assert_not identity.valid?
    assert_includes identity.errors[:uid], "can't be blank"
  end

  test 'validates provider is in allowed list' do
    identity = Identity.new(provider: 'invalid', uid: '12345')
    assert_not identity.valid?
    assert_includes identity.errors[:provider], 'is not included in the list'
  end

  test 'display_name returns proper name for github' do
    identity = Identity.new(provider: 'github', uid: '123')
    assert_equal 'GitHub', identity.display_name
  end

  test 'display_name returns proper name for google' do
    identity = Identity.new(provider: 'google', uid: '123')
    assert_equal 'Google', identity.display_name
  end

  test 'display_name returns proper name for email' do
    identity = Identity.new(provider: 'email', uid: '123')
    assert_equal 'Email', identity.display_name
  end

  test 'icon_name returns correct icon for each provider' do
    github_identity = Identity.new(provider: 'github', uid: '123')
    assert_equal 'github', github_identity.icon_name

    google_identity = Identity.new(provider: 'google', uid: '456')
    assert_equal 'google', google_identity.icon_name

    email_identity = Identity.new(provider: 'email', uid: '789')
    assert_equal 'envelope', email_identity.icon_name
  end

  test 'can_unlink? returns true' do
    identity = Identity.new(provider: 'github', uid: '123')
    assert identity.can_unlink?
  end
end

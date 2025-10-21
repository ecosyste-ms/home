require 'test_helper'

class IdentityTest < ActiveSupport::TestCase
  def setup
    @account = Account.create!(
      name: 'Test User',
      email: 'test@example.com'
    )
  end

  test 'creates an identity with valid attributes' do
    identity = @account.identities.new(
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
    identity = @account.identities.new(uid: '12345')
    assert_not identity.valid?
    assert_includes identity.errors[:provider], "can't be blank"
  end

  test 'requires uid' do
    identity = @account.identities.new(provider: 'github')
    assert_not identity.valid?
    assert_includes identity.errors[:uid], "can't be blank"
  end

  test 'validates provider is in allowed list' do
    identity = @account.identities.new(provider: 'invalid', uid: '12345')
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

  test 'can_unlink? returns false when only identity' do
    identity = @account.identities.create!(provider: 'github', uid: '123')
    assert_not identity.can_unlink?
  end

  test 'can_unlink? returns true when multiple identities' do
    identity1 = @account.identities.create!(provider: 'github', uid: '123')
    identity2 = @account.identities.create!(provider: 'google', uid: '456')
    assert identity1.can_unlink?
    assert identity2.can_unlink?
  end
end

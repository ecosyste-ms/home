class Identity < ApplicationRecord
  belongs_to :account

  encrypts :token
  encrypts :refresh_token

  validates :provider, presence: true, inclusion: { in: %w[github email google] }
  validates :uid, presence: true
  validates :provider, uniqueness: { scope: :uid }

  scope :for_provider, ->(provider) { where(provider: provider) }

  def display_name
    case provider
    when 'github'
      'GitHub'
    when 'google'
      'Google'
    when 'email'
      'Email'
    else
      provider.capitalize
    end
  end

  def icon_name
    case provider
    when 'github'
      'github'
    when 'google'
      'google'
    when 'email'
      'envelope'
    else
      'key'
    end
  end

  def can_unlink?
    account.identities.count > 1
  end

  def self.find_or_create_from_omniauth(auth_hash)
    find_or_create_by(provider: auth_hash['provider'], uid: auth_hash['uid']) do |identity|
      identity.email = auth_hash.dig('info', 'email')
      identity.username = auth_hash.dig('info', 'nickname')
      identity.name = auth_hash.dig('info', 'name')
      identity.avatar_url = auth_hash.dig('info', 'image')
      identity.token = auth_hash.dig('credentials', 'token')
      identity.refresh_token = auth_hash.dig('credentials', 'refresh_token')
      identity.token_expires_at = auth_hash.dig('credentials', 'expires_at') ?
        Time.at(auth_hash.dig('credentials', 'expires_at')) : nil
      identity.data = auth_hash
    end
  end
end

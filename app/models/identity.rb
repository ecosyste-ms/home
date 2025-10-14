class Identity
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :provider, :string
  attribute :uid, :string
  attribute :username, :string
  attribute :email, :string
  attribute :created_at, :datetime

  validates :provider, presence: true, inclusion: { in: %w[github email google] }
  validates :uid, presence: true

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
    # Don't allow unlinking if it's the only authentication method
    # This logic would be more complex with actual DB queries
    true
  end
end

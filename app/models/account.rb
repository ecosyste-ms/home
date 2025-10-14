class Account
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :show_profile_picture, :boolean, default: true
  attribute :plan_name, :string, default: 'Pro'
  attribute :next_payment_date, :date
  attribute :api_key, :string
  attribute :payment_method_type, :string, default: 'Mastercard'
  attribute :payment_method_last4, :string
  attribute :payment_method_expiry, :string

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def identities
    @identities ||= []
  end

  def add_identity(identity)
    identities << identity
  end

  def profile_picture_url
    github_identity = identities.find { |i| i.provider == 'github' }
    return "https://github.com/#{github_identity.username}.png" if github_identity
    nil
  end

  def plan
    @plan ||= Plan.find_by_name(plan_name)
  end

  def plan_requests
    plan&.requests_per_hour || 0
  end

  def plan_price
    plan&.price_per_month || 0
  end

  def plan_billing_period
    plan&.billing_period || 'monthly'
  end

  # Mock data for demonstration
  def self.current
    account = new(
      name: 'Ben Nicholls',
      email: 'ben@ecosyste.ms',
      plan_name: 'Pro',
      next_payment_date: Date.new(2026, 6, 18),
      api_key: 'XMCM6-DKYCQ-2BHQH-4PCHR-TBJCR',
      payment_method_type: 'Mastercard',
      payment_method_last4: '2342',
      payment_method_expiry: '09/2026',
      show_profile_picture: true
    )

    # Add mock identities
    account.add_identity(Identity.new(
      provider: 'github',
      username: 'benjam',
      uid: '12345'
    ))

    account
  end

  def billing_history
    Billing.for_account(email)
  end
end

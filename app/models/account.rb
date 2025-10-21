class Account < ApplicationRecord
  has_many :identities, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :plans, through: :subscriptions
  has_many :api_keys, dependent: :destroy
  has_many :invoices, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :status, inclusion: { in: %w[active suspended deleted] }

  scope :active, -> { where(status: 'active').where(deleted_at: nil) }
  scope :suspended, -> { where(status: 'suspended') }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def current_subscription
    subscriptions.where(status: ['active', 'trialing']).order(created_at: :desc).first
  end

  def plan
    current_subscription&.plan
  end

  def plan_name
    plan&.name || 'Free'
  end

  def plan_requests
    plan&.requests_per_hour || 0
  end

  def plan_price
    plan&.price_dollars || 0
  end

  def plan_billing_period
    plan&.billing_period || 'month'
  end

  def next_payment_date
    current_subscription&.current_period_end
  end

  def pending_invoice
    invoices.where(status: ['draft', 'open']).order(due_date: :asc).first
  end

  def billing_history
    invoices.where(status: 'paid').order(created_at: :desc)
  end

  def active?
    status == 'active' && deleted_at.nil?
  end

  def suspended?
    status == 'suspended'
  end

  def deleted?
    deleted_at.present?
  end

  def suspend!
    update(status: 'suspended', suspended_at: Time.current)
  end

  def activate!
    update(status: 'active', suspended_at: nil)
  end

  def soft_delete!
    update(status: 'deleted', deleted_at: Time.current)
  end

  def profile_picture_url
    return super if super.present?

    github_identity = identities.find_by(provider: 'github')
    return "https://github.com/#{github_identity.username}.png" if github_identity&.username

    nil
  end
end

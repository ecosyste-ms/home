class Plan < ApplicationRecord
  has_many :subscriptions, dependent: :restrict_with_error
  has_many :accounts, through: :subscriptions

  before_validation :generate_slug, if: -> { has_attribute?(:slug) && slug.blank? }
  before_validation :set_defaults, if: -> { has_attribute?(:slug) }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, if: -> { has_attribute?(:slug) }
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :billing_period, presence: true, inclusion: { in: %w[month year] }
  validates :requests_per_hour, presence: true, numericality: { greater_than: 0 }

  scope :available, -> { where(active: true, public: true, deleted_at: nil).order(:position) }
  scope :active_plans, -> { where(active: true, deleted_at: nil) }
  scope :grandfathered, -> { where(active: true, public: false, deleted_at: nil) }
  scope :by_position, -> { order(:position) }

  store_accessor :metadata,
    :tagline,            # short blurb
    :access_type,        # "Common or polite pools" | "API Key"
    :quota_reset,        # "hourly" | "daily"
    :daily_quota_total,  # integer (for daily plans)
    :burst_requests,     # true/false
    :priority,           # "Standard" | "High priority"
    :support_level,      # "Community" | "Priority"
    :sla_level,          # "None" | "Standard" | "Commercial"
    :license_name,       # default: "CC BY-SA 4.0"
    :dashboard_access    # true/false

  def price_dollars
    price_cents / 100.0
  end

  def price_dollars=(dollars)
    self.price_cents = (dollars.to_f * 100).to_i
  end

  def free?
    price_cents.zero?
  end

  def formatted_price
    return 'Free' if free?
    "$#{price_dollars.to_i}"
  end

  def formatted_requests
    requests_per_hour.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def daily_quota_total_int
    daily_quota_total.to_i if daily_quota_total.present?
  end

  def rate_summary
    if quota_reset == "daily"
      total = daily_quota_total_int ? " (#{daily_quota_total_int.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} total requests)" : ""
      "#{formatted_requests} req/hour • resets daily#{total}"
    else
      "#{formatted_requests} req/hour • resets hourly"
    end
  end

  def license_name
    super.presence || "CC BY-SA 4.0"
  end

  def access_type
    super.presence || "API Key"
  end

  def quota_reset
    super.presence || "hourly"
  end

  def burst_requests
    ActiveModel::Type::Boolean.new.cast(super)
  end

  def priority
    super.presence || "Standard"
  end

  def support_level
    super.presence || "Community"
  end

  def sla_level
    super.presence || "None"
  end

  def dashboard_access
    ActiveModel::Type::Boolean.new.cast(super)
  end

  def active?
    active && deleted_at.nil?
  end

  def grandfathered?
    active && !public
  end

  def deprecated?
    !active
  end

  def soft_delete!
    update(deleted_at: Time.current, visible: false, active: false, public: false)
  end

  def grandfather!
    update(public: false, visible: false)
  end

  def deprecate!
    update(active: false, public: false, visible: false)
  end

  def subscriber_count
    subscriptions.where(status: ['active', 'trialing']).count
  end

  private

  def generate_slug
    return if name.blank?
    base_slug = name.parameterize
    self.slug = base_slug

    counter = 2
    while Plan.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  def set_defaults
    return if name.blank?
    self.display_name ||= name
    self.plan_family ||= name.downcase.gsub(/\s+v?\d+$/, '')
  end
end
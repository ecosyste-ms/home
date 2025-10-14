class Plan
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :requests_per_hour, :integer
  attribute :price_per_month, :integer
  attribute :billing_period, :string, default: 'monthly'
  attribute :active, :boolean, default: true

  attr_accessor :features

  validates :name, presence: true
  validates :requests_per_hour, presence: true, numericality: { greater_than: 0 }
  validates :price_per_month, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :billing_period, inclusion: { in: %w[monthly yearly] }

  def self.all
    [
      new(
        name: 'Free',
        requests_per_hour: 300,
        price_per_month: 0,
        billing_period: 'monthly'
      ).tap { |p| p.features = [
        'Basic rate limiting',
        'Community support',
        'Access to all APIs'
      ] },
      new(
        name: 'Pro',
        requests_per_hour: 5000,
        price_per_month: 200,
        billing_period: 'monthly'
      ).tap { |p| p.features = [
        'Enhanced rate limiting',
        'Priority support',
        'Access to all APIs',
        'Usage analytics'
      ] },
      new(
        name: 'Enterprise',
        requests_per_hour: 20000,
        price_per_month: 800,
        billing_period: 'monthly'
      ).tap { |p| p.features = [
        'Maximum rate limiting',
        'Dedicated support',
        'Access to all APIs',
        'Advanced analytics',
        'Custom integrations',
        'SLA guarantee'
      ] }
    ]
  end

  def self.find_by_name(name)
    all.find { |plan| plan.name == name }
  end

  def free?
    price_per_month.zero?
  end

  def formatted_price
    return 'Free' if free?
    "$#{price_per_month}"
  end

  def formatted_requests
    "#{requests_per_hour.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} requests"
  end
end

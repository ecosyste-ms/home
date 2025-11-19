class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :plan
  belongs_to :scheduled_plan, class_name: 'Plan', optional: true
  has_many :invoices, dependent: :nullify

  validates :status, presence: true, inclusion: {
    in: %w[active trialing past_due canceled incomplete incomplete_expired unpaid]
  }

  scope :active, -> { where(status: 'active') }
  scope :trialing, -> { where(status: 'trialing') }
  scope :current, -> { where(status: ['active', 'trialing']).order(created_at: :desc) }

  def trialing?
    status == 'trialing'
  end

  def active?
    status == 'active'
  end

  def past_due?
    status == 'past_due'
  end

  def canceled?
    status == 'canceled'
  end

  def canceling?
    cancel_at_period_end?
  end

  def schedule_plan_change(new_plan)
    update(
      scheduled_plan: new_plan,
      scheduled_change_date: current_period_end
    )
  end

  def cancel_scheduled_change
    update(scheduled_plan: nil, scheduled_change_date: nil)
  end

  def cancel_at_period_end!
    update(cancel_at_period_end: true, canceled_at: Time.current)
  end

  def cancel_immediately!
    update(
      status: 'canceled',
      canceled_at: Time.current,
      ended_at: Time.current
    )
  end

  def reactivate!
    update(cancel_at_period_end: false, canceled_at: nil) if canceling?
  end

  def sync_from_stripe(stripe_subscription)
    update!(self.class.stripe_attributes(stripe_subscription))
  end

  def self.stripe_attributes(stripe_subscription)
    # Stripe API 2025-03-31 moved current_period_start/end from subscription to items
    # Extract billing period from first subscription item
    first_item = stripe_subscription.items&.data&.first

    {
      status: stripe_subscription.status,
      current_period_start: first_item&.current_period_start ? Time.at(first_item.current_period_start) : nil,
      current_period_end: first_item&.current_period_end ? Time.at(first_item.current_period_end) : nil,
      cancel_at_period_end: stripe_subscription.cancel_at_period_end || false
    }
  end
end

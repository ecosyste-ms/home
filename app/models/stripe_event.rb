class StripeEvent < ApplicationRecord
  validates :event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending processed failed] }

  scope :pending, -> { where(status: 'pending') }
  scope :processed, -> { where(status: 'processed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) }

  def pending?
    status == 'pending'
  end

  def processed?
    status == 'processed'
  end

  def failed?
    status == 'failed'
  end

  def mark_as_processed!
    update!(status: 'processed', processed_at: Time.current)
  end

  def mark_as_failed!(error)
    update!(
      status: 'failed',
      processed_at: Time.current,
      error_message: error.message
    )
  end
end

class Invoice < ApplicationRecord
  belongs_to :account
  belongs_to :subscription, optional: true

  validates :status, presence: true, inclusion: {
    in: %w[draft open paid uncollectible void]
  }
  validates :amount_due_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_paid_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :draft, -> { where(status: 'draft') }
  scope :open, -> { where(status: 'open') }
  scope :paid, -> { where(status: 'paid') }
  scope :unpaid, -> { where(status: ['draft', 'open']) }
  scope :overdue, -> { where(status: 'open').where('due_date < ?', Time.current) }

  def amount_due_dollars
    amount_due_cents / 100.0
  end

  def amount_due_dollars=(dollars)
    self.amount_due_cents = (dollars.to_f * 100).to_i
  end

  def amount_paid_dollars
    amount_paid_cents / 100.0
  end

  def amount_paid_dollars=(dollars)
    self.amount_paid_cents = (dollars.to_f * 100).to_i
  end

  def formatted_amount
    "$#{'%.2f' % amount_due_dollars}"
  end

  def paid?
    status == 'paid'
  end

  def open?
    status == 'open'
  end

  def draft?
    status == 'draft'
  end

  def overdue?
    open? && due_date.present? && due_date < Time.current
  end

  def mark_paid!
    update(status: 'paid', paid_at: Time.current, amount_paid_cents: amount_due_cents)
  end

  def mark_void!
    update(status: 'void')
  end

  def mark_uncollectible!
    update(status: 'uncollectible')
  end

  def finalize!
    update(status: 'open') if draft?
  end

  def month
    (period_start || created_at).strftime('%B %Y')
  end

  def invoice_url
    hosted_invoice_url || "#"
  end
end

class Billing
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :account_email, :string
  attribute :month, :string
  attribute :amount, :integer
  attribute :invoice_date, :date
  attribute :invoice_number, :string
  attribute :invoice_url, :string
  attribute :status, :string, default: 'paid'

  validates :account_email, presence: true
  validates :month, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[pending paid failed] }

  def formatted_amount
    "$#{sprintf('%.2f', amount)}"
  end

  def paid?
    status == 'paid'
  end

  def self.for_account(account_email)
    (1..9).map do |i|
      date = Date.new(2025, 9, 1) + i.months
      new(
        account_email: account_email,
        month: date.strftime('%B %Y'),
        amount: 200,
        invoice_date: date,
        invoice_number: "INV-#{date.strftime('%Y%m')}-#{account_email.split('@').first.upcase}",
        invoice_url: "#",
        status: 'paid'
      )
    end
  end

  def self.latest_for_account(account_email)
    for_account(account_email).last
  end
end

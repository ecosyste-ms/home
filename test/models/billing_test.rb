require 'test_helper'

class BillingTest < ActiveSupport::TestCase
  test 'creates a billing record with valid attributes' do
    billing = Billing.new(
      account_email: 'test@example.com',
      month: 'January 2026',
      amount: 200,
      invoice_date: Date.new(2026, 1, 1),
      invoice_number: 'INV-202601-TEST',
      invoice_url: '#',
      status: 'paid'
    )

    assert billing.valid?
    assert_equal 'test@example.com', billing.account_email
    assert_equal 'January 2026', billing.month
    assert_equal 200, billing.amount
  end

  test 'requires account_email' do
    billing = Billing.new(month: 'January 2026', amount: 200)
    assert_not billing.valid?
    assert_includes billing.errors[:account_email], "can't be blank"
  end

  test 'requires month' do
    billing = Billing.new(account_email: 'test@example.com', amount: 200)
    assert_not billing.valid?
    assert_includes billing.errors[:month], "can't be blank"
  end

  test 'requires amount' do
    billing = Billing.new(account_email: 'test@example.com', month: 'January 2026')
    assert_not billing.valid?
    assert_includes billing.errors[:amount], "can't be blank"
  end

  test 'validates status is in allowed list' do
    billing = Billing.new(
      account_email: 'test@example.com',
      month: 'January 2026',
      amount: 200,
      status: 'invalid'
    )
    assert_not billing.valid?
    assert_includes billing.errors[:status], 'is not included in the list'
  end

  test 'formatted_amount returns dollar formatted string' do
    billing = Billing.new(amount: 200)
    assert_equal '$200.00', billing.formatted_amount
  end

  test 'paid? returns true for paid status' do
    billing = Billing.new(status: 'paid')
    assert billing.paid?
  end

  test 'paid? returns false for non-paid status' do
    billing = Billing.new(status: 'pending')
    assert_not billing.paid?
  end

  test 'for_account returns array of billing records' do
    billings = Billing.for_account('test@example.com')

    assert_equal 9, billings.length
    assert_instance_of Billing, billings.first
    assert_equal 'test@example.com', billings.first.account_email
  end

  test 'for_account generates correct invoice numbers' do
    billings = Billing.for_account('ben@ecosyste.ms')

    assert_match(/INV-\d{6}-BEN/, billings.first.invoice_number)
  end

  test 'latest_for_account returns most recent billing' do
    billing = Billing.latest_for_account('test@example.com')

    assert_instance_of Billing, billing
    assert_equal 'test@example.com', billing.account_email
  end

  test 'billing records have sequential months' do
    billings = Billing.for_account('test@example.com')

    assert_equal 9, billings.length
    assert billings.first.month != billings.last.month
  end
end

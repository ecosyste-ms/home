FactoryBot.define do
  factory :subscription do
    account
    plan
    status { 'active' }
    current_period_start { Time.current }
    current_period_end { 1.month.from_now }
  end
end

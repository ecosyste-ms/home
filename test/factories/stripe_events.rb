FactoryBot.define do
  factory :stripe_event do
    sequence(:event_id) { |n| "evt_test_#{n}" }
    event_type { 'customer.subscription.updated' }
    status { 'pending' }
    data { { 'id' => event_id, 'type' => event_type } }
  end
end

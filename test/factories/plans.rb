FactoryBot.define do
  factory :plan do
    name { 'Pro' }
    price_cents { 20000 }
    billing_period { 'month' }
    requests_per_hour { 5000 }
    visible { true }
    position { 1 }

    trait :free do
      name { 'Free' }
      price_cents { 0 }
      requests_per_hour { 300 }
    end

    trait :enterprise do
      name { 'Enterprise' }
      price_cents { 80000 }
      requests_per_hour { 20000 }
    end
  end
end

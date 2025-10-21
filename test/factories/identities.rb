FactoryBot.define do
  factory :identity do
    account
    provider { 'github' }
    sequence(:uid) { |n| n.to_s }
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
  end
end

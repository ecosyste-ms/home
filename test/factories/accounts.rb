FactoryBot.define do
  factory :account do
    email { "user-#{SecureRandom.hex(8)}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    status { 'active' }
  end
end

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating plans..."

Plan.find_or_create_by(slug: 'free') do |plan|
  plan.name = 'Free'
  plan.price_cents = 0
  plan.billing_period = 'month'
  plan.requests_per_hour = 300
  plan.description = 'Perfect for getting started and trying out the API'
  plan.features = [
    'Basic rate limiting',
    'Community support',
    'Access to all APIs'
  ]
  plan.position = 1
  plan.visible = true
end

Plan.find_or_create_by(slug: 'pro') do |plan|
  plan.name = 'Pro'
  plan.price_cents = 20000
  plan.billing_period = 'month'
  plan.requests_per_hour = 5000
  plan.description = 'For developers building production applications'
  plan.features = [
    'Enhanced rate limiting',
    'Priority support',
    'Access to all APIs',
    'Usage analytics'
  ]
  plan.position = 2
  plan.visible = true
end

Plan.find_or_create_by(slug: 'enterprise') do |plan|
  plan.name = 'Enterprise'
  plan.price_cents = 80000
  plan.billing_period = 'month'
  plan.requests_per_hour = 20000
  plan.description = 'For large scale applications with enterprise needs'
  plan.features = [
    'Maximum rate limiting',
    'Dedicated support',
    'Access to all APIs',
    'Advanced analytics',
    'Custom integrations',
    'SLA guarantee'
  ]
  plan.position = 3
  plan.visible = true
end

puts "Created #{Plan.count} plans"

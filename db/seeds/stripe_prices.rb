# Stripe Price IDs for different environments
#
# To set up your development environment:
# 1. Run: stripe login
# 2. Run: rails stripe:create_prices
# 3. Price IDs will be automatically assigned
#
# Or manually create prices in Stripe Dashboard and update these:

STRIPE_PRICES = {
  development: {
    # These are example IDs - replace with your actual test mode price IDs
    # Or run: rails stripe:create_prices to create them automatically
    'developer' => ENV['STRIPE_DEVELOPER_PRICE_ID'], # e.g., price_test_...
    'business' => ENV['STRIPE_BUSINESS_PRICE_ID'],
    'enterprise' => ENV['STRIPE_ENTERPRISE_PRICE_ID']
  },

  production: {
    # Production price IDs - set via environment variables
    'developer' => ENV['STRIPE_DEVELOPER_PRICE_ID'],
    'business' => ENV['STRIPE_BUSINESS_PRICE_ID'],
    'enterprise' => ENV['STRIPE_ENTERPRISE_PRICE_ID']
  }
}

# Apply price IDs based on environment
env_prices = STRIPE_PRICES[Rails.env.to_sym] || {}

env_prices.each do |slug, price_id|
  next if price_id.blank?

  plan = Plan.find_by(slug: slug)
  if plan
    plan.update!(stripe_price_id: price_id)
    puts "Updated #{plan.name} with price ID: #{price_id}"
  end
end

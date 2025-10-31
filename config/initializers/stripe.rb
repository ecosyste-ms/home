Stripe.api_key = ENV['STRIPE_SECRET_KEY']
Stripe.api_version = '2025-10-29.clover'

# For displaying publishable key in views
Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY']
}

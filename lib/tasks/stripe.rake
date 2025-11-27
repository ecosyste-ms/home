namespace :stripe do
  desc "Sync Stripe prices from Stripe to local database"
  task sync_prices: :environment do
    require 'stripe'

    puts "Fetching prices from Stripe..."

    prices = Stripe::Price.list(active: true, expand: ['data.product'])

    prices.auto_paging_each do |price|
      next unless price.recurring # Only sync recurring prices

      product = price.product

      # Try to find plan by name or create mapping
      plan = Plan.find_by(name: product.name)

      if plan
        plan.update!(stripe_price_id: price.id)
        puts "✓ Updated #{plan.name} with price #{price.id}"
      else
        puts "⚠ No plan found for product: #{product.name} (#{price.id})"
      end
    end

    puts "\nDone! Plans updated with Stripe price IDs."
  end

  desc "Create Stripe prices for all plans without price IDs"
  task create_prices: :environment do
    require 'stripe'

    Plan.where(stripe_price_id: nil).where.not(price_cents: 0).each do |plan|
      next if plan.free?

      puts "Creating Stripe price for: #{plan.name}..."

      # Create product
      product = Stripe::Product.create(
        name: plan.name,
        description: "#{plan.requests_per_hour} requests per hour"
      )

      # Create price
      price = Stripe::Price.create(
        product: product.id,
        unit_amount: plan.price_cents,
        currency: 'usd',
        recurring: {
          interval: plan.billing_period
        }
      )

      # Update plan
      plan.update!(stripe_price_id: price.id)

      puts "✓ Created price #{price.id} for #{plan.name}"
    rescue Stripe::StripeError => e
      puts "✗ Failed to create price for #{plan.name}: #{e.message}"
    end

    puts "\nDone!"
  end

  desc "Update Stripe prices where local price_cents differs from Stripe (creates new price, archives old)"
  task update_prices: :environment do
    require 'stripe'

    puts "Checking for price changes..."

    Plan.where.not(stripe_price_id: nil).where.not(price_cents: 0).each do |plan|
      stripe_price = Stripe::Price.retrieve(plan.stripe_price_id)

      if stripe_price.unit_amount != plan.price_cents
        puts "\n#{plan.name}: $#{stripe_price.unit_amount / 100} -> $#{plan.price_cents / 100}"

        # Create new price on the same product
        new_price = Stripe::Price.create(
          product: stripe_price.product,
          unit_amount: plan.price_cents,
          currency: 'usd',
          recurring: {
            interval: plan.billing_period
          }
        )

        # Archive old price
        Stripe::Price.update(plan.stripe_price_id, active: false)

        # Update plan with new price ID
        plan.update!(stripe_price_id: new_price.id)

        puts "  Created new price: #{new_price.id}"
        puts "  Archived old price: #{stripe_price.id}"
      else
        puts "#{plan.name}: no change ($#{plan.price_cents / 100})"
      end
    rescue Stripe::StripeError => e
      puts "Failed for #{plan.name}: #{e.message}"
    end

    puts "\nDone!"
  end

  desc "List all Stripe prices"
  task list_prices: :environment do
    require 'stripe'

    puts "\n=== Stripe Prices ==="

    prices = Stripe::Price.list(active: true, expand: ['data.product'])

    prices.auto_paging_each do |price|
      next unless price.recurring

      product = price.product
      amount = "$#{price.unit_amount / 100.0}"
      interval = price.recurring.interval

      puts "\n#{product.name}"
      puts "  Price ID: #{price.id}"
      puts "  Amount: #{amount}/#{interval}"
      puts "  Product ID: #{product.id}"
    end

    puts "\n=== Local Plans ==="

    Plan.all.each do |plan|
      puts "\n#{plan.name}"
      puts "  Stripe Price ID: #{plan.stripe_price_id || 'NOT SET'}"
      puts "  Amount: $#{plan.price_dollars}/#{plan.billing_period}"
    end
  end
end

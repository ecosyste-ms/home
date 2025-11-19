class StripeService
  class StripeError < StandardError; end

  def initialize(account = nil)
    @account = account
  end

  # Create or retrieve a Stripe customer for an account
  def create_or_retrieve_customer
    return nil unless @account

    if @account.stripe_customer_id.present?
      begin
        Stripe::Customer.retrieve(@account.stripe_customer_id)
      rescue Stripe::InvalidRequestError
        # Customer doesn't exist, create new one
        create_customer
      end
    else
      create_customer
    end
  end

  # Create a subscription for an account
  def create_subscription(plan:, payment_method_id:)
    raise StripeError, 'Account is required' unless @account
    raise StripeError, 'Plan is required' unless plan
    raise StripeError, 'Plan must have a Stripe price ID' unless plan.stripe_price_id.present?

    customer = create_or_retrieve_customer

    # Attach payment method to customer
    payment_method = Stripe::PaymentMethod.attach(
      payment_method_id,
      { customer: customer.id }
    )

    # Set as default payment method
    Stripe::Customer.update(
      customer.id,
      invoice_settings: { default_payment_method: payment_method.id }
    )

    # Create subscription with expanded items for billing period data
    # Stripe API 2025-03-31: latest_invoice now has confirmation_secret instead of payment_intent
    stripe_subscription = Stripe::Subscription.create(
      customer: customer.id,
      items: [{ price: plan.stripe_price_id }],
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice', 'items.data']
    )

    # Create local subscription record
    subscription = @account.subscriptions.create!(
      Subscription.stripe_attributes(stripe_subscription).merge(
        plan: plan,
        stripe_subscription_id: stripe_subscription.id,
        stripe_price_id: plan.stripe_price_id
      )
    )

    # Update account with payment method info
    update_account_payment_method(payment_method)

    {
      subscription: subscription,
      client_secret: stripe_subscription.latest_invoice&.confirmation_secret
    }
  rescue Stripe::StripeError => e
    Rails.logger.error "[StripeService] Error creating subscription: #{e.message}"
    raise StripeError, e.message
  end

  # Cancel a subscription
  def cancel_subscription(subscription, immediately: false)
    raise StripeError, 'Subscription is required' unless subscription
    raise StripeError, 'Subscription must have a Stripe subscription ID' unless subscription.stripe_subscription_id.present?

    if immediately
      stripe_subscription = Stripe::Subscription.cancel(subscription.stripe_subscription_id)
      subscription.cancel_immediately!
    else
      stripe_subscription = Stripe::Subscription.update(
        subscription.stripe_subscription_id,
        cancel_at_period_end: true
      )
      subscription.cancel_at_period_end!
    end

    stripe_subscription
  rescue Stripe::StripeError => e
    Rails.logger.error "[StripeService] Error canceling subscription: #{e.message}"
    raise StripeError, e.message
  end

  # Update subscription to a new plan
  def update_subscription(subscription, new_plan)
    raise StripeError, 'Subscription is required' unless subscription
    raise StripeError, 'New plan is required' unless new_plan
    raise StripeError, 'Subscription must have a Stripe subscription ID' unless subscription.stripe_subscription_id.present?
    raise StripeError, 'New plan must have a Stripe price ID' unless new_plan.stripe_price_id.present?

    stripe_subscription = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)

    stripe_subscription = Stripe::Subscription.update(
      subscription.stripe_subscription_id,
      items: [{
        id: stripe_subscription.items.data[0].id,
        price: new_plan.stripe_price_id
      }],
      proration_behavior: 'create_prorations'
    )

    subscription.update!(
      plan: new_plan,
      stripe_price_id: new_plan.stripe_price_id
    )

    stripe_subscription
  rescue Stripe::StripeError => e
    Rails.logger.error "[StripeService] Error updating subscription: #{e.message}"
    raise StripeError, e.message
  end

  # Retrieve payment method details
  def retrieve_payment_method
    return nil unless @account&.stripe_customer_id

    customer = Stripe::Customer.retrieve(
      @account.stripe_customer_id,
      { expand: ['invoice_settings.default_payment_method'] }
    )

    customer.invoice_settings&.default_payment_method
  rescue Stripe::StripeError => e
    Rails.logger.error "[StripeService] Error retrieving payment method: #{e.message}"
    nil
  end

  # Update account payment method
  def update_payment_method(payment_method_id)
    raise StripeError, 'Account is required' unless @account

    customer = create_or_retrieve_customer

    payment_method = Stripe::PaymentMethod.attach(
      payment_method_id,
      { customer: customer.id }
    )

    Stripe::Customer.update(
      customer.id,
      invoice_settings: { default_payment_method: payment_method.id }
    )

    update_account_payment_method(payment_method)

    payment_method
  rescue Stripe::StripeError => e
    Rails.logger.error "[StripeService] Error updating payment method: #{e.message}"
    raise StripeError, e.message
  end

  private

  def create_customer
    customer = Stripe::Customer.create(
      email: @account.email,
      name: @account.name,
      metadata: { account_id: @account.id }
    )

    @account.update!(stripe_customer_id: customer.id)
    customer
  end

  def update_account_payment_method(payment_method)
    return unless payment_method && @account

    case payment_method.type
    when 'card'
      @account.update!(
        payment_method_type: payment_method.card.brand.titleize,
        payment_method_last4: payment_method.card.last4,
        payment_method_expiry: "#{payment_method.card.exp_month}/#{payment_method.card.exp_year}"
      )
    end
  end
end

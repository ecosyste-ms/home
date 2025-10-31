class CheckoutController < ApplicationController
  before_action :require_authentication
  before_action :set_plan

  def new
    @meta_title = "Checkout - #{@plan.name}"
    @current_plan = current_account.plan

    # Redirect if already on this plan
    if @current_plan == @plan
      redirect_to plan_account_path, alert: 'You are already subscribed to this plan.'
      return
    end
  end

  def create
    stripe_service = StripeService.new(current_account)

    result = stripe_service.create_subscription(
      plan: @plan,
      payment_method_id: params[:payment_method_id]
    )

    if result[:client_secret]
      # Payment requires additional action (3D Secure)
      render json: {
        requires_action: true,
        client_secret: result[:client_secret]
      }
    else
      # Subscription created successfully
      render json: {
        success: true,
        redirect_url: billing_account_path
      }
    end
  rescue StripeService::StripeError => e
    Rails.logger.error "[Checkout] Stripe error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "[Checkout] Unexpected error: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    render json: { error: 'An unexpected error occurred. Please try again.' }, status: :internal_server_error
  end

  private

  def set_plan
    # Allow checkout of any active plan (including private/grandfathered ones) via direct UUID link
    # This enables sharing private plan links with specific customers
    @plan = Plan.active_plans.find_by!(uuid: params[:plan_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to plan_account_path, alert: 'Plan not found.'
  end

  def require_authentication
    unless current_account
      redirect_to login_path, alert: 'Please sign in to continue.'
    end
  end
end

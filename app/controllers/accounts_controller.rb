class AccountsController < ApplicationController
  before_action :set_account

  def show
    @meta_title = "Account Overview - #{@account.name}"
    @meta_description = "Manage your ecosyste.ms account settings, plan, API keys, and billing information."
  end

  def details
    @meta_title = "Account Details - #{@account.name}"
  end

  def update_details
    if @account.update(account_params)
      redirect_to details_account_path, notice: 'Your details have been updated successfully.'
    else
      flash.now[:alert] = 'Please correct the errors below.'
      render :details
    end
  end

  def plan
    @meta_title = "Plan - #{@account.name}"
    @plans = Plan.available
  end

  def api_key
    @meta_title = "API Key - #{@account.name}"
    @api_keys = @account.api_keys.active.order(created_at: :desc)
  end

  def create_api_key
    Rails.logger.info "[API Key Creation] Starting for account_id=#{@account.id}, name=#{params[:name].inspect}"

    # Build the API key without saving
    api_key = @account.api_keys.build(
      name: params[:name] || "API Key #{@account.api_keys.count + 1}"
    )
    Rails.logger.info "[API Key Creation] Built API key with name=#{api_key.name}"

    # Generate the key (triggers before_create callback)
    api_key.send(:generate_key)
    api_key.key_hash = BCrypt::Password.create(api_key.raw_key)
    api_key.key_prefix = api_key.raw_key[0, 8]
    Rails.logger.info "[API Key Creation] Generated key with prefix=#{api_key.key_prefix}"

    # Create consumer in APISIX first
    apisix_service = apisix_service_for_env
    Rails.logger.info "[API Key Creation] Calling APISIX to create consumer with prefix=#{api_key.key_prefix}, rate_limit=#{@account.plan_requests}"
    consumer_id = apisix_service.create_consumer(
      consumer_name: api_key.key_prefix,
      api_key: api_key.raw_key,
      requests_per_hour: @account.plan_requests,
      metadata: {
        name: api_key.name,
        account_id: @account.id,
        email: @account.email,
        plan_name: @account.plan_name
      }
    )
    Rails.logger.info "[API Key Creation] APISIX consumer created successfully, consumer_id=#{consumer_id}"

    # Only save to database if APISIX succeeded
    api_key.apisix_consumer_id = consumer_id
    Rails.logger.info "[API Key Creation] Saving API key to database"
    api_key.save!
    Rails.logger.info "[API Key Creation] API key saved successfully, id=#{api_key.id}"

    flash[:new_api_key] = api_key.raw_key
    redirect_to api_key_account_path
  rescue ApisixService::ApisixError, ApisixStubService::ApisixError => e
    Rails.logger.error "[API Key Creation] APISIX error: #{e.class} - #{e.message}"
    Rails.logger.error "[API Key Creation] Backtrace: #{e.backtrace.first(5).join("\n")}"
    redirect_to api_key_account_path, alert: "Failed to create API key: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "[API Key Creation] Unexpected error: #{e.class} - #{e.message}"
    Rails.logger.error "[API Key Creation] Backtrace: #{e.backtrace.first(5).join("\n")}"
    redirect_to api_key_account_path, alert: "Failed to create API key: #{e.message}"
  end

  def revoke_api_key
    api_key = @account.api_keys.find(params[:api_key_id])

    # Delete from APISIX first
    if api_key.apisix_consumer_id.present?
      apisix_service = apisix_service_for_env
      apisix_service.delete_consumer(consumer_name: api_key.apisix_consumer_id)
    end

    # Only revoke in database if APISIX succeeded
    api_key.revoke!

    redirect_to api_key_account_path, notice: 'API Key has been revoked.'
  rescue ApisixService::ApisixError, ApisixStubService::ApisixError => e
    redirect_to api_key_account_path, alert: "Failed to revoke API key: #{e.message}"
  end

  def billing
    @meta_title = "Billing - #{@account.name}"

    # Fetch payment method from Stripe if available
    if @account.stripe_customer_id.present? && @account.payment_method_type.blank?
      stripe_service = StripeService.new(@account)
      payment_method = stripe_service.retrieve_payment_method

      if payment_method && payment_method.type == 'card'
        @account.update(
          payment_method_type: payment_method.card.brand.titleize,
          payment_method_last4: payment_method.card.last4,
          payment_method_expiry: "#{payment_method.card.exp_month}/#{payment_method.card.exp_year}"
        )
      end
    end
  end

  def update_payment_method
    stripe_service = StripeService.new(@account)

    begin
      stripe_service.update_payment_method(params[:payment_method_id])
      render json: { success: true }
    rescue StripeService::StripeError => e
      Rails.logger.error "[Account] Failed to update payment method: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def security
    @meta_title = "Password and Security - #{@account.name}"
    @identities = @account.identities.order(created_at: :asc)
  end

  def unlink_identity
    identity = @account.identities.find(params[:identity_id])

    if identity.can_unlink?
      identity.destroy
      redirect_to security_account_path, notice: "#{identity.display_name} has been unlinked."
    else
      redirect_to security_account_path, alert: "Cannot unlink your only authentication method."
    end
  end

  private

  def set_account
    @account = current_account
  end

  def account_params
    params.require(:account).permit(:name, :email, :show_profile_picture)
  end

  def apisix_service_for_env
    if Rails.env.development? || Rails.env.test?
      ApisixStubService.new
    else
      ApisixService.new
    end
  end
end

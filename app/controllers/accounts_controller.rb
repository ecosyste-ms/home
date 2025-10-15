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
    api_key = @account.api_keys.create!(
      name: params[:name] || "API Key #{@account.api_keys.count + 1}"
    )

    redirect_to api_key_account_path, notice: "API Key created: #{api_key.raw_key}. Save this key - you won't see it again!"
  end

  def revoke_api_key
    api_key = @account.api_keys.find(params[:api_key_id])
    api_key.revoke!

    redirect_to api_key_account_path, notice: 'API Key has been revoked.'
  end

  def billing
    @meta_title = "Billing - #{@account.name}"
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
end

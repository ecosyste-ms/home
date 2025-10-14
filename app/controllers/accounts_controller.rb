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
    @account.assign_attributes(account_params)

    if @account.valid?
      # In a real implementation, this would save to database or session
      flash[:notice] = 'Your details have been updated successfully.'
      redirect_to details_account_path
    else
      flash.now[:alert] = 'Please correct the errors below.'
      render :details
    end
  end

  def plan
    @meta_title = "Plan - #{@account.name}"
  end

  def api_key
    @meta_title = "API Key - #{@account.name}"
  end

  def billing
    @meta_title = "Billing - #{@account.name}"
  end

  def security
    @meta_title = "Password and Security - #{@account.name}"
  end

  def update_security
    # Password update logic would go here
    flash[:notice] = 'Your security settings have been updated successfully.'
    redirect_to security_account_path
  end

  private

  def set_account
    @account = Account.current
  end

  def account_params
    params.require(:account).permit(:name, :email, :show_profile_picture)
  end
end

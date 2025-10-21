class Admin::SubscriptionsController < Admin::BaseController
  before_action :set_subscription, only: [:show, :cancel, :reactivate]

  def index
    @subscriptions = Subscription.includes(:account, :plan).order(created_at: :desc)

    if params[:status].present?
      @subscriptions = @subscriptions.where(status: params[:status])
    end

    if params[:plan_id].present?
      @subscriptions = @subscriptions.where(plan_id: params[:plan_id])
    end
  end

  def show
    @account = @subscription.account
  end

  def cancel
    @subscription.cancel_immediately!
    redirect_to admin_subscription_path(@subscription), notice: 'Subscription canceled.'
  end

  def reactivate
    @subscription.reactivate!
    redirect_to admin_subscription_path(@subscription), notice: 'Subscription reactivated.'
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end
end

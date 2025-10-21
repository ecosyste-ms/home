class Admin::DashboardController < Admin::BaseController
  def index
    @total_accounts = Account.active.count
    @suspended_accounts = Account.suspended.count
    @total_subscriptions = Subscription.active.count
    @plans = Plan.active_plans.order(:position)

    @recent_accounts = Account.active.order(created_at: :desc).limit(10)
    @recent_subscriptions = Subscription.order(created_at: :desc).limit(10)

    @mrr = calculate_mrr
  end

  private

  def calculate_mrr
    Subscription.active.joins(:plan).sum('plans.price_cents') / 100.0
  end
end

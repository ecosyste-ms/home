class Admin::AccountsController < Admin::BaseController
  before_action :set_account, only: [:show, :suspend, :unsuspend, :impersonate]

  def index
    @accounts = Account.includes(:identities, :subscriptions).order(created_at: :desc)

    if params[:status].present?
      @accounts = @accounts.where(status: params[:status])
    end

    if params[:plan_id].present?
      @accounts = @accounts.joins(:subscriptions)
                          .where(subscriptions: { plan_id: params[:plan_id], status: ['active', 'trialing'] })
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @accounts = @accounts.where('email ILIKE ? OR name ILIKE ?', search_term, search_term)
    end
  end

  def show
    @subscription = @account.current_subscription
    @identities = @account.identities.order(created_at: :asc)
    @api_keys = @account.api_keys.order(created_at: :desc).limit(10)
    @invoices = @account.invoices.order(created_at: :desc).limit(10)
  end

  def suspend
    @account.suspend!
    redirect_to admin_account_path(@account), notice: 'Account has been suspended.'
  end

  def unsuspend
    @account.activate!
    redirect_to admin_account_path(@account), notice: 'Account has been reactivated.'
  end

  def impersonate
    session[:admin_id] = current_account.id
    session[:account_id] = @account.id
    redirect_to account_path, notice: "Now viewing as #{@account.name}"
  end

  def stop_impersonating
    if session[:admin_id]
      session[:account_id] = session[:admin_id]
      session[:admin_id] = nil
      redirect_to admin_root_path, notice: 'Stopped impersonating'
    else
      redirect_to admin_root_path
    end
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end
end

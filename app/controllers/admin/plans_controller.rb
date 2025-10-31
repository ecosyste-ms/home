class Admin::PlansController < Admin::BaseController
  before_action :set_plan, only: [:show, :edit, :update, :destroy, :grandfather, :deprecate]

  def index
    @plans = Plan.order(plan_family: :asc, version: :desc)
    @plans_by_family = @plans.group_by(&:plan_family)
  end

  def show
    @subscriptions = @plan.subscriptions.where(status: ['active', 'trialing']).includes(:account).order(created_at: :desc)
  end

  def new
    @plan = Plan.new
  end

  def create
    @plan = Plan.new(plan_params)

    if @plan.save
      redirect_to admin_plan_path(@plan), notice: 'Plan created successfully.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @plan.subscriptions.where(status: ['active', 'trialing']).exists?
      redirect_to admin_plan_path(@plan), alert: 'Cannot edit plan with active subscribers. Create a new version instead.'
      return
    end

    if @plan.update(plan_params)
      redirect_to admin_plan_path(@plan), notice: 'Plan updated successfully.'
    else
      render :edit
    end
  end

  def destroy
    if @plan.subscriptions.exists?
      redirect_to admin_plans_path, alert: 'Cannot delete plan with subscriptions.'
    else
      @plan.destroy
      redirect_to admin_plans_path, notice: 'Plan deleted successfully.'
    end
  end

  def grandfather
    @plan.grandfather!
    redirect_to admin_plan_path(@plan), notice: 'Plan is now grandfathered (hidden from pricing page).'
  end

  def deprecate
    if @plan.subscriptions.where(status: ['active', 'trialing']).exists?
      redirect_to admin_plan_path(@plan), alert: 'Cannot deprecate plan with active subscribers.'
    else
      @plan.deprecate!
      redirect_to admin_plan_path(@plan), notice: 'Plan deprecated.'
    end
  end

  private

  def set_plan
    @plan = Plan.find_by!(uuid: params[:id])
  end

  def plan_params
    params.require(:plan).permit(
      :name, :slug, :display_name, :description, :price_cents,
      :currency, :billing_period, :requests_per_hour, :stripe_price_id,
      :plan_family, :version, :active, :public, :visible, :position,
      features: []
    )
  end
end

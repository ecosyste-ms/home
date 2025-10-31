module Admin
  class StripeEventsController < ApplicationController
    before_action :require_admin

    def index
      @stripe_events = StripeEvent.recent

      # Filter by status
      if params[:status].present?
        @stripe_events = @stripe_events.where(status: params[:status])
      end

      # Filter by event type
      if params[:event_type].present?
        @stripe_events = @stripe_events.where(event_type: params[:event_type])
      end

      @stripe_events = @stripe_events.page(params[:page]).per(50)

      @event_types = StripeEvent.distinct.pluck(:event_type).sort
    end

    def show
      @stripe_event = StripeEvent.find(params[:id])
    end

    private

    def require_admin
      unless current_account&.admin?
        redirect_to root_path, alert: 'Access denied.'
      end
    end
  end
end

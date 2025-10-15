class Admin::BaseController < ApplicationController
  before_action :require_login
  before_action :require_admin

  layout 'admin'

  private

  def require_admin
    unless current_account&.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
end

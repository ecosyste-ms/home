class ApplicationController < ActionController::Base
  before_action :redirect_subdomain

  def redirect_subdomain
    if request.host == 'www.ecosyste.ms'
      redirect_to 'http://ecosyste.ms' + request.fullpath, :status => 301
    end
  end
end

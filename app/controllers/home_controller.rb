class HomeController < ApplicationController
  skip_before_action :require_login

  def index
    if request.host == 'styleguide.ecosyste.ms'
      render 'pages/styleguide'
    end
  end
end

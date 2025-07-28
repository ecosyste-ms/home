class HomeController < ApplicationController
  def index
    if request.host == 'styleguide.ecosyste.ms'
      render 'pages/styleguide'
    end
  end
end

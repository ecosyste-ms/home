Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unprocessable'
  get '/500', to: 'errors#internal'

  get '/privacy', to: 'pages#privacy'
  get '/terms', to: 'pages#terms'
  get '/api', to: 'pages#api'
  get '/openapi.yml', to: 'pages#openapi'
  get '/commercial', to: 'pages#commercial'

  get '/styleguide', to: 'pages#styleguide'

  get "/accountblank", to: "pages#accountblank"

  # Defines the root path route ("/")
  root "home#index"
end

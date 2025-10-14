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
  get '/pricing', to: 'pages#pricing'

  get '/styleguide', to: 'pages#styleguide'

  resource :account, only: [:show] do
    get :details, on: :member
    patch :update_details, on: :member
    get :plan, on: :member
    get :api_key, on: :member
    get :billing, on: :member
    get :security, on: :member
    patch :update_security, on: :member
  end

  root "home#index"
end

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
  get '/about', to: 'pages#about'

  get '/checkout-success', to: 'pages#checkout_success'

  get '/styleguide', to: 'pages#styleguide'

  # Authentication routes
  get '/login', to: 'sessions#new', as: :login
  delete '/logout', to: 'sessions#destroy', as: :logout
  post '/auth/:provider', to: 'sessions#create', as: :auth
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'

  # Account management
  resource :account, only: [:show] do
    get :details, on: :member
    patch :update_details, on: :member
    get :plan, on: :member
    get :api_key, on: :member
    post :create_api_key, on: :member
    delete 'api_keys/:api_key_id', to: 'accounts#revoke_api_key', on: :member, as: :revoke_api_key
    get :billing, on: :member
    post :update_payment_method, on: :member
    get :security, on: :member
    delete 'identities/:identity_id', to: 'accounts#unlink_identity', on: :member, as: :unlink_identity
  end

  # Checkout and subscriptions
  get '/checkout/:plan_id', to: 'checkout#new', as: :checkout
  post '/checkout/:plan_id', to: 'checkout#create', as: :create_checkout

  # Stripe webhooks
  post '/webhooks/stripe', to: 'webhooks/stripe#create'

  # Admin panel
  namespace :admin do
    root to: 'dashboard#index'

    resources :accounts, only: [:index, :show] do
      member do
        post :suspend
        post :unsuspend
        post :impersonate
      end
    end

    post '/stop_impersonating', to: 'accounts#stop_impersonating', as: :stop_impersonating

    resources :plans do
      member do
        post :grandfather
        post :deprecate
      end
    end

    resources :subscriptions, only: [:index, :show] do
      member do
        post :cancel
        post :reactivate
      end
    end

    resources :stripe_events, only: [:index, :show]
  end

  root "home#index"
end

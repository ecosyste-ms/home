class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create, :failure]

  def new
  end

  def create
    auth_hash = request.env['omniauth.auth']

    identity = Identity.find_or_create_from_omniauth(auth_hash)

    if identity.account
      session[:account_id] = identity.account.id
      redirect_to account_path, notice: "Successfully signed in!"
    else
      account = Account.create!(
        name: auth_hash.dig('info', 'name') || auth_hash.dig('info', 'nickname'),
        email: auth_hash.dig('info', 'email'),
        profile_picture_url: auth_hash.dig('info', 'image')
      )

      identity.update!(account: account)
      session[:account_id] = account.id

      redirect_to account_path, notice: "Welcome! Your account has been created."
    end
  rescue => e
    Rails.logger.error "OAuth error: #{e.message}"
    redirect_to login_path, alert: "Authentication failed. Please try again."
  end

  def destroy
    session[:account_id] = nil
    redirect_to root_path, notice: "You have been logged out."
  end

  def failure
    redirect_to login_path, alert: "Authentication failed: #{params[:message]}"
  end
end

class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }
  before_action :redirect_if_authenticated, only: %i[ new create ]


  def new
  end

  def create
    result = Sessions::AuthenticateService.call(email_address: params[:email_address], password: params[:password])

    if result.success?
      start_new_session_for result.data
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: result.error
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

   private

  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end
end

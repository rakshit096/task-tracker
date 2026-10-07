class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :redirect_if_authenticated, only: %i[ new create ]


  def new
    @user = User.new
  end

  def create
    result = Registrations::CreateService.call(params: user_params)

    if result.success?
      start_new_session_for result.data
      redirect_to root_path, notice: "Welcome! Your account is created."
    else
      @user = result.data
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password)
  end

  private

  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end
end

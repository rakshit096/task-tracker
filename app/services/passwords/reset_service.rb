class Passwords::ResetService
  def self.call(...)
    new(...).call
  end

  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    if @user.update(@params)
      @user.sessions.destroy_all
      ServiceResult.success(@user)
    else
      ServiceResult.error("Passwords did not match.")
    end
  end
end

class Sessions::AuthenticateService
  def self.call(...)
    new(...).call
  end

  def initialize(email_address:, password:)
    @email_address = email_address
    @password = password
  end

  def call
    user = User.authenticate_by(email_address: @email_address, password: @password)

    if user
      ServiceResult.success(user)
    else
      ServiceResult.error("Try another email address or password.")
    end
  end
end

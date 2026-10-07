class Registrations::CreateService
  def self.call(...)
    new(...).call
  end

  def initialize(params:)
    @params = params
  end

  def call
    user = User.new(@params)

    if user.save
      ServiceResult.success(user)
    else
      ServiceResult.error(user.errors.full_messages.to_sentence, data: user)
    end
  end
end

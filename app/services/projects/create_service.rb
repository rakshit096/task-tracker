class Projects:: CreateService
  def self.call(...)
    new(...).call
  end

  def initialize(user:, params:)
    @user=user
    @params=params
  end

  def call
    project = @user.projects.new(@params)

    if project.save
      ServiceResult.success(project)
    else
      ServiceResult.error(project.errors.full_messages.to_sentence, data: project)
    end
  end
end

class Projects::UpdateService
  def self.call(...)
    new(...).call
  end

  def initialize(project:, params:, user:)
    @project = project
    @params = params
    @user = user
  end

  def call
    if @project.update(@params)
      ServiceResult.success(@project)
    else
      ServiceResult.error(@project.errors.full_messages.to_sentence, data: @project)
    end
  end
end

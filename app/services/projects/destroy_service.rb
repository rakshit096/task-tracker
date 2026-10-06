class Projects::DestroyService
  def self.call(...)
    new(...).call
  end

  def initialize(project:, user:)
    @project = project
    @user = user
  end

  def call
    if @project.destroy
      ServiceResult.success(@project)
    else
      ServiceResult.error(@project.errors.full_messages.to_sentence, data: @project)
    end
  end
end

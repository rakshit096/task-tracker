class Tasks::CreateService
  def self.call(...)
    new(...).call
  end

  def initialize(project:, params:, user:)
    @project = project
    @params = params
    @user = user
  end

  def call
    task = @project.tasks.new(@params)

    if task.save
      notify_assignee(task) if task.assignee_id.present?
      ServiceResult.success(task)
    else
      ServiceResult.error(task.errors.full_messages.to_sentence, data: task)
    end
  end

  private

  def notify_assignee(task)
    TaskAssignmentNotifierJob.perform_later(task)
  end
end

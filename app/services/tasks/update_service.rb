class Tasks::UpdateService
  def self.call(...)
    new(...).call
  end

  def initialize(task:, params:, user:)
    @task = task
    @params = params
    @user = user
  end

  def call
    previous_assignee_id = @task.assignee_id

    if @task.update(@params)
      notify_assignee if @task.assignee_id != previous_assignee_id && @task.assignee_id.present?
      ServiceResult.success(@task)
    else
      ServiceResult.error(@task.errors.full_messages.to_sentence)
    end
  end

  private

  def notify_assignee
    TaskAssignmentNotifierJob.perform_later(@task)
  end
end

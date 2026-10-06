class Tasks::UpdateStatusService
  def self.call(...)
    new(...).call
  end

  def initialize(task:, status:, user:)
    @task = task
    @status = status
    @user = user
  end

  def call
    return ServiceResult.error("Invalid status value") unless Task.statuses.key?(@status)

    @task.status = @status

    if @task.save
      notify_if_assignee_changed
      ServiceResult.success(@task)
    else
      ServiceResult.error(@task.errors.full_messages.to_sentence)
    end
  end

  private

  def notify_if_assignee_changed
    # status updates never change assignee, so nothing to trigger here —
    # left as a placeholder to show where a service-owned side effect would go.
  end
end
class Tasks::DestroyService
  def self.call(...)
    new(...).call
  end

  def initialize(task:, user:)
    @task = task
    @user = user
  end

  def call
    if @task.destroy
      ServiceResult.success(@task)
    else
      ServiceResult.error(@task.errors.full_messages.to_sentence, data: @task)
    end
  end
end

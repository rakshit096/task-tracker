class TaskMailer < ApplicationMailer
  def assigned(task)
    @task = task
    @user = task.assignee
    mail to: @user.email_address, subject: "You've been assigned: #{@task.title}"
  end
end
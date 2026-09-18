# Preview all emails at http://localhost:3000/rails/mailers/task_mailer
class TaskMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/task_mailer/assigned
  def assigned
    TaskMailer.assigned
  end
end

require "test_helper"

class TaskMailerTest < ActionMailer::TestCase
  test "assigned" do
    user = users(:one)
    project = Project.create!(name: "Mailer Test Project", user: user)
    task = project.tasks.create!(title: "Mailer Test Task", assignee: user)

    mail = TaskMailer.assigned(task)

    assert_equal "You've been assigned: #{task.title}", mail.subject
    assert_equal [ user.email_address ], mail.to
    assert_match task.title, mail.body.encoded
  end
end

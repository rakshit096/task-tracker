require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @project = Project.create!(name: "Test Project", user: @user)
  end

  test "valid with a title and project" do
    task = Task.new(title: "Do something", project: @project)
    assert task.valid?
  end

  test "invalid without a title" do
    task = Task.new(title: "", project: @project)
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "defaults to pending status" do
    task = Task.create!(title: "New task", project: @project)
    assert task.pending?
  end

  test "can be assigned to a user" do
    task = Task.create!(title: "Assigned task", project: @project, assignee: @user)
    assert_equal @user, task.assignee
  end

  test "is valid without an assignee" do
    task = Task.new(title: "Unassigned task", project: @project)
    assert task.valid?
  end

  test "enqueues a notification job when assignee changes" do
    task = Task.create!(title: "Task", project: @project)
    assert_enqueued_with(job: TaskAssignmentNotifierJob) do
      task.update!(assignee: @user)
    end
  end

  test "does not enqueue a job when assignee is unchanged" do
    task = Task.create!(title: "Task", project: @project, assignee: @user)
    assert_no_enqueued_jobs only: TaskAssignmentNotifierJob do
      task.update!(title: "Renamed")
    end
  end
    include ActiveJob::TestHelper
end

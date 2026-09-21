require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @project = Project.create!(name: "My Project", user: @user)
    @other_project = Project.create!(name: "Their Project", user: @other_user)
    @task = @project.tasks.create!(title: "Existing Task")
    @other_task = @other_project.tasks.create!(title: "Their Task")
  end

  test "can create a task in own project" do
    sign_in_as(@user)
    assert_difference("Task.count", 1) do
      post project_tasks_path(@project), params: { task: { title: "New Task" } }
    end
    assert_redirected_to project_path(@project)
  end

  test "cannot create a task in another user's project" do
    sign_in_as(@user)
    assert_no_difference("Task.count") do
      post project_tasks_path(@other_project), params: { task: { title: "Sneaky Task" } }
    end
    assert_response :not_found
  end

  test "can edit own task" do
    sign_in_as(@user)
    get edit_project_task_path(@project, @task)
    assert_response :success
  end

  test "cannot edit a task in another user's project" do
    sign_in_as(@user)
    get edit_project_task_path(@other_project, @other_task)
    assert_response :not_found
  end

  test "can update own task's status" do
    sign_in_as(@user)
    patch update_status_project_task_path(@project, @task), params: { status: "done" }
    @task.reload
    assert @task.done?
  end

  test "cannot update status of a task in another user's project" do
    sign_in_as(@user)
    patch update_status_project_task_path(@other_project, @other_task), params: { status: "done" }
    assert_response :not_found
    assert_not @other_task.reload.done?
  end

  test "cannot delete a task in another user's project" do
    sign_in_as(@user)
    assert_no_difference("Task.count") do
      delete project_task_path(@other_project, @other_task)
    end
    assert_response :not_found
  end

  test "assigning a task enqueues a notification job" do
    sign_in_as(@user)
    assert_enqueued_with(job: TaskAssignmentNotifierJob) do
      patch project_task_path(@project, @task), params: { task: { assignee_id: @user.id } }
    end
  end
end
require "test_helper"

class ProjectControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user=users(:one)
    @other_user=users(:two)
    @project= Project.create!(name: "my Project", user: @user)
    @other_project=Project.create!(name: "Their project", user: @other_user)
  end

  test "redirects to login when not authenticated" do
    get projects_path
    assert_redirected_to new_session_path
  end

  test "shows only the current user's projects" do
    sign_in_as(@user)
    get projects_path
    assert_response :success
    assert_match @project.name, response.body
    assert_no_match @other_project.name, response.body
  end

  test "can view own project" do
    sign_in_as(@user)
    get project_path(@project)
    assert_response :success
  end

  test "cannot view another user's project" do
    sign_in_as(@user)
    get project_path(@other_project)
    assert_response :not_found
  end

  test "can create a project" do
    sign_in_as(@user)
    assert_difference("Project.count", 1) do
      post projects_path, params: { project: { name: "New One", description: "desc" } }
    end
    assert_redirected_to project_path(Project.last)
  end

  test "cannot delete another user's project" do
    sign_in_as(@user)
    assert_no_difference("Project.count") do
      delete project_path(@other_project)
    end
    assert_response :not_found
  end
end

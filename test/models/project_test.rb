require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do                #Runs before every single test. It prepares common variables so you don't repeat setup code (keeping tests DRY).
    @user=users(:one)     #ab the fake user named 'one' from the fixture file, so I have a real, valid User to attach my test Project to.
  end

  test "valid with a name and user" do
    project = Project.new(name: "New Project", user: @user)
    assert project.valid?
  end

  test "invalid without a name" do
    project = Project.new(name: "", user: @user)
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "invalid with a duplicate name for the same user" do
    Project.create!(name: "Website", user: @user)
    duplicate = Project.new(name: "Website", user: @user)
    assert_not duplicate.valid?
  end

  test "valid with the same name for a different user" do
    Project.create!(name: "Website", user: @user)
    other_user = users(:two)
    project = Project.new(name: "Website", user: other_user)
    assert project.valid?
  end

  test "destroying a project destroys its tasks" do
    project = Project.create!(name: "Temp", user: @user)
    project.tasks.create!(title: "A task")
    assert_difference("Task.count", -1) do
      project.destroy
    end
  end
end

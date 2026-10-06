class ProjectsController < ApplicationController
  before_action :set_project, only: %i[ show edit update destroy ]

  def index
    @projects = Current.user.admin? ? Project.all : Current.user.projects
  end

  def show
    @unassigned_tasks = @project.tasks.unassigned
    @assigned_tasks = @project.tasks.assigned.includes(:assignee)
  end

  def new
    @project = Current.user.projects.new
  end

  def create
    result = Projects::CreateService.call(user: Current.user, params: project_params)

    if result.success?
      redirect_to result.data, notice: "Project created."
    else
      @project = result.data
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    result = Projects::UpdateService.call(project: @project, params: project_params, user: Current.user)

    if result.success?
      redirect_to @project, notice: "Project updated."
    else
      @project = result.data
      flash.now[:alert] = result.error
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = Projects::DestroyService.call(project: @project, user: Current.user)

    if result.success?
      redirect_to projects_path, notice: "Project deleted."
    else
      redirect_to @project, alert: result.error
    end
  end

  private

  def set_project
    @project = Current.user.admin? ? Project.find(params[:id]) : Current.user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :status)
  end
end

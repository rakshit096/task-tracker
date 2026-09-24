class ProjectsController < ApplicationController
  before_action :set_project, only: %i[ show edit update destroy ]
  before_action :authorize_owner!, only: %i[ edit update ]
  before_action :authorize_delete!, only: :destroy

  def index
    @projects = Current.user.admin? ? Project.all : Current.user.projects
  end

  def show
  end

  def new
    @project = Current.user.projects.new
  end

  def create
    @project = Current.user.projects.new(project_params)
    if @project.save
      redirect_to @project, notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  private

  def set_project
    @project = Current.user.admin? ? Project.find(params[:id]) : Current.user.projects.find(params[:id])
  end

  def authorize_owner!
    head :not_found unless @project.user == Current.user || Current.user.admin?
  end

  def authorize_delete!
    head :not_found unless @project.user == Current.user || Current.user.admin?
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
class TasksController < ApplicationController
  before_action :set_project, except: %i[ assigned_to_me ]
  before_action :set_task, only: %i[ show edit update destroy update_status ]
  before_action :authorize_viewer!, only: %i[ show update_status ]
  before_action :authorize_owner!, only: %i[ new create edit update ]
  before_action :authorize_delete!, only: :destroy
  skip_before_action :set_project, only: :assigned_to_me

  def show
  end

  def new
    @task = @project.tasks.new
  end

  def create
    @task = @project.tasks.new(task_params)
    if @task.save
      redirect_to @project, notice: "Task added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to @project, notice: "Task updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_status
    @task.update(status: params[:status])
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project }
    end
  end

  def destroy
    @task.destroy
    redirect_to @project, notice: "Task deleted."
  end

  def assigned_to_me
    @tasks = Current.user.assigned_tasks.includes(:project)
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  end

  def authorize_viewer!
    unless @project.user == Current.user || @task&.assignee == Current.user || Current.user.admin?
      head :not_found 
    end
  end

  def authorize_owner!
    head :not_found unless @project.user == Current.user || Current.user.admin?
  end

  def authorize_delete!
    head :not_found unless @project.user == Current.user || Current.user.admin?
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :assignee_id)
  end
end

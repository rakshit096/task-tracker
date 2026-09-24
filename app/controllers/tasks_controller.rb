class TasksController < ApplicationController
  before_action :set_project, except: :assigned_to_me  # Tasks belong to a project. Load the project for every action except when listing tasks across all projects."
  before_action :set_task, only: %i[ show edit update destroy update_status ]
  before_action :authorize_viewer!, only: %i[ show update_status ]
  before_action :authorize_owner!, only: %i[ new create edit update destroy ]

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
    if params[:status].in?(Task.statuses.keys)
      @task.update(status: params[:status])
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @project, notice: "Status updated." }
      end
    else
      redirect_to @project, alert: "Invalid status value."
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
    unless @project.user == Current.user || @task.assignee == Current.user || Current.user.admin?
      head :not_found
    end
  end

  def authorize_owner!
    head :not_found unless @project.user == Current.user || Current.user.admin?
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :assignee_id)
  end
end

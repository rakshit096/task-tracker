class TasksController < ApplicationController
  before_action :set_project
  before_action :set_task, only: %i[ edit update destroy update_status ]

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

  private

  def set_project
    @project = Current.user.projects.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :assignee_id)
  end
end

class TaskAssignmentNotifierJob < ApplicationJob
  queue_as :default

  def perform(task)
    return unless task.assignee
    TaskMailer.assigned(task).deliver_now
  end
end
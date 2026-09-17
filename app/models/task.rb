class Task < ApplicationRecord
  belongs_to :project
  belongs_to :assignee, class_name: "User", optional: true
  enum :status, { pending: 0, in_progress: 1, done: 2 }, default: :pending

  validates :title, presence: true
end

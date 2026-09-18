class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :projects, dependent: :destroy
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify # if user is deleted. Dont delete their specified task

  has_secure_token :api_token

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end

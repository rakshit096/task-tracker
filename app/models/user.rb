class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :projects, dependent: :destroy
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify # if user is deleted. Dont delete their specified task

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :password, length: { minimum: 8 }, allow_nil: true

  after_initialize { self.role ||= "user" }  # If role is currently nil or false, assign "user" to it. Otherwise, keep the current role value.

  def admin?
    role == "admin"
  end
end

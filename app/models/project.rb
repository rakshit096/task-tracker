class Project < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy   # if project is deleted then the tasks under it gets deleted

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }

    enum :status, { planning: 0, in_progress: 1, completed: 2, on_hold: 3 }, default: :planning

end

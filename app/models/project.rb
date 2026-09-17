class Project < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy   #if project is deleted then the tasks under it gets deleted

  validates :name, presence: true
end

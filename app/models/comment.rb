class Comment < ApplicationRecord
  belongs_to :game

  validates :message, presence: true
end

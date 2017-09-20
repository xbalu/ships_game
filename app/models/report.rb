class Report < ApplicationRecord
  validates :text, presence: true, length: { minimum: 12, maximum: 1024 }
end

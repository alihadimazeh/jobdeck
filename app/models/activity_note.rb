class ActivityNote < ApplicationRecord
  belongs_to :notable, polymorphic: true

  validates :body, presence: true
end

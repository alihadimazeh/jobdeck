class Job < ApplicationRecord
  enum :status, { active: 0, on_hold: 1, completed: 2, cancelled: 3 }, suffix: true
  enum :job_type, { tile: 0, flooring: 1, materials: 2, kitchen: 3, mixed: 4 }, suffix: true

  validates :title, presence: true

  belongs_to :customer
  belongs_to :lead, optional: true

  has_many :orders, dependent: :restrict_with_error
  has_many :activity_notes, as: :notable, dependent: :destroy
  has_many :documents, as: :documentable, dependent: :destroy

  # Whole days an active job has run past its end_date, or nil when it's on schedule (or has
  # no end date). Only an active job can run over - a completed one finished when it finished.
  def days_over
    return unless active_status? && end_date
    days = (Date.current - end_date).to_i
    days if days.positive?
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[title status job_type start_date end_date]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[customer]
  end
end

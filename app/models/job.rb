class Job < ApplicationRecord
  enum :status, { active: 0, on_hold: 1, completed: 2, cancelled: 3 }
  enum :job_type, { tile: 0, flooring: 1, materials: 2, kitchen: 3, mixed: 4 }

  belongs_to :customer
  belongs_to :lead
end

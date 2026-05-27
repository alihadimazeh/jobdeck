class Lead < ApplicationRecord
  enum :status, { new: 0, contacted: 1, quoted: 2, converted: 3, lost: 4 }
  enum :job_type, { tile: 0, flooring: 1, materials: 2, kitchen: 3, mixed: 4 }
  enum :source, { walk_in: 0, referral: 1, other: 2 }

  belongs_to :customer
  has_one :job
end

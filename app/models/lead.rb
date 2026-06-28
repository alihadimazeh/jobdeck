class Lead < ApplicationRecord
  enum :status, { new: 0, contacted: 1, quoted: 2, converted: 3, lost: 4 }, suffix: true
  enum :job_type, { tile: 0, flooring: 1, materials: 2, kitchen: 3, mixed: 4 }, suffix: true
  enum :source, { walk_in: 0, referral: 1, phone: 2, website: 3, other: 4 }

  belongs_to :customer
  has_one :job, dependent: :nullify
end

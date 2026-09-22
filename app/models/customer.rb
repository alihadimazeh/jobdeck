class Customer < ApplicationRecord
  # Client-side hint for the phone <input pattern> - browsers compile `pattern` with the
  # regex `v` flag, where ( ) - must be escaped inside a class or the whole pattern is
  # silently ignored (verified in Chrome). Deliberately loose; not enforced server-side.
  PHONE_INPUT_PATTERN = '[0-9+\\-\\s\\(\\)\\.]{7,}'.freeze

  enum :status, { active: "active", inactive: "inactive", archived: "archived" }, suffix: true

  validates :status, presence: true
  validates :first_name, :last_name, :phone, presence: true

  has_many :jobs,   dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :leads,  dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :activity_notes, as: :notable, dependent: :destroy

  scope :visible, -> { where.not(status: :archived) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def archive!
    update!(status: "archived")
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name phone email status]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end

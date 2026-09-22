class Customer < ApplicationRecord
  enum :status, { active: "active", inactive: "inactive", archived: "archived" }, suffix: true

  validates :status, presence: true
  validates :first_name, :last_name, :phone, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  normalizes :email, with: ->(email) { email.strip }

  has_many :jobs,   dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :leads,  dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :activity_notes, as: :notable, dependent: :destroy

  scope :visible, -> { where.not(status: :archived) }

  def full_name
    "#{first_name} #{last_name}"
  end

  # System-driven (a blocked delete), not a user edit - skip validations so an unrelated
  # legacy value (e.g. an email saved before format validation existed) can't block it.
  def archive!
    update_attribute(:status, "archived")
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name phone email status]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end

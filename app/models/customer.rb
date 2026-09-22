class Customer < ApplicationRecord
  enum :status, { active: "active", inactive: "inactive", archived: "archived" }, suffix: true

  validates :status, presence: true
  validates :first_name, :last_name, :phone, presence: true

  has_many :jobs,   dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :leads,  dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :activity_notes, as: :notable, dependent: :destroy
  has_many :documents,      as: :documentable, dependent: :destroy

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

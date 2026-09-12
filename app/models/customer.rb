class Customer < ApplicationRecord
  enum :status, { active: "active", inactive: "inactive" }, suffix: true

  validates :status, presence: true
  validates :first_name, :last_name, :phone, presence: true

  has_many :jobs,   dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :leads,  dependent: :destroy
  has_many :quotes, dependent: :destroy

  def full_name
    "#{first_name} #{last_name}"
  end
end

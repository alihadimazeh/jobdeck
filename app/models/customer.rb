class Customer < ApplicationRecord
  has_many :leads,  dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :jobs,   dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error

  def full_name
    "#{first_name} #{last_name}"
  end
end

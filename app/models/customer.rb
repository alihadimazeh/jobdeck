class Customer < ApplicationRecord
  has_many :leads, dependent: :destroy
  has_many :jobs

  def full_name
    "#{first_name} #{last_name}"
  end
end

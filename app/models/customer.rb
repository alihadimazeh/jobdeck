class Customer < ApplicationRecord
  has_many :leads
  has_many :jobs
end

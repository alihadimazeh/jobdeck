class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  # Salted into the generated token so it stops validating the moment the
  # password changes (has_secure_password exposes #password_salt for this).
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end
end

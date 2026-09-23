class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token

  enum :role, {customer: 0, admin: 1}, default: :customer
  validates :email, presence: true, uniqueness: true
end

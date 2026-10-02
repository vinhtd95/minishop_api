class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token

  enum :role, {customer: 0, admin: 1}, default: :customer
  validates :email, presence: true, uniqueness: true

  has_one :cart, dependent: :destroy 
  has_many :orders, dependent: :destroy 
  has_many :order_items, through: :orders
end

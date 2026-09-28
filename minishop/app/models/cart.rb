class Cart < ApplicationRecord
  belongs_to :user

  has_many :cart_items, dependent: :destroy 
  has_many :products, through: :cart_items  #đi tắt qua bảng trung gian, gọi được product từ cart mà ko cần qua cart_items 

  def total_cents
    cart_items.includes(:product).sum do |item|
      price_cents = ((item.product&.price || 0) * 100).to_i
      price_cents * item.quantity
    end
  end
end

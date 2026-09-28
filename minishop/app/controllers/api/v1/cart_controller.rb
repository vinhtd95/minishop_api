class Api::V1::CartController < Api::V1::BaseController
  before_action :authenticate_api_user!

  def show 
    cart = current_user.cart ||current_user.create_cart!
    render json: format_cart_response(cart)
  end

  private 
  def format_cart_response(cart)
    {
      items: cart.cart_items.includes(:product).map do |item|
        price_cents = ((item.product&.price || 0) * 100).to_i
        {
          id: item.id,
          product_id: item.product_id,
          product_name: item.product.name, 
          price_cents: price_cents,
          quantity: item.quantity,
          total_cents: price_cents * item.quantity
        }
      end,
      total_cents: cart.total_cents
    }
  end
end 
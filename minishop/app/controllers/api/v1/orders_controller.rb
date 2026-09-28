class Api::V1::OrdersController < Api::V1::BaseController
  before_action :authenticate_api_user!
  before_action :set_order, only: [:show]

  #GET /api/v1/orders
  def index 
    orders = current_user.orders.order(created_at: :desc)
    render json: orders.map {|order| format_order_response(order)}, status: :ok
  end

  #GET /api/v1/order/:id 
  def show 
    render json: format_order_response(@order), status: :ok
  end

  #POST /api/vi/orders 
  def create
    cart = current_user.cart
  
    if cart.nil? || cart.cart_items.empty?
      return render json: { error: "Cart is empty" }, status: :unprocessable_entity
    end

    order = nil
    ActiveRecord::Base.transaction do
      order = current_user.orders.create!(
        status: :pending,
        total_cents: cart.total_cents
      )
      cart.cart_items.includes(:product).each do |cart_item|
        price_cents = ((cart_item.product.price || 0) * 100).to_i

        order.order_items.create!(
          product: cart_item.product,
          quantity: cart_item.quantity,
          unit_price_cents: price_cents
        )
      end
      cart.cart_items.destroy_all
    end

    render json: format_order_response(order), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end


  private
  def set_order
    @order = current_user.orders.find_by(id: params[:id]) 
    unless @order
      render json: {error: "Order not found"}, status: :not_found 
    end
  end

  def format_order_response(order)
    {
      id: order.id,
      status: order.status,
      total_cents: order.total_cents,
      created_at: order.created_at,
      items: order.order_items.includes(:product).map do |item|
        {
          id: item.id,
          product_id: item.product_id,
          product_name: item.product.name,
          quantity: item.quantity,
          unit_price_cents: item.unit_price_cents,
          subtotal_cents: item.unit_price_cents * item.quantity
        }
      end
    }
  end
end

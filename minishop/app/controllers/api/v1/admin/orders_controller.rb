class Api::V1::Admin::OrdersController < Api::V1::BaseController
  before_action :require_admin! 
  before_action :set_order, only: [:update]

  #GET /api/v1/admin/orders?status=
  def index 
    orders = Order.all.order(created_at: :desc)
    orders = orders.where(status: params[:status]) if params[:status].present?
    render json: orders.map{|order| format_order_response(order)}, status: :ok
  end

  #PATCH /api/v1/admin/orders/:id
  def update 
    new_status = params[:status]
    if @order.valid_transition_to?(new_status)
      if @order.update(status: new_status)
        # Gửi email nếu trạng thái mới là shipped
        OrderMailer.shipped(@order).deliver_later if new_status.to_s == "shipped"
        render json: format_order_response(@order), status: :ok
      end
    else
      render json: {error: @order.errors.full_messages}, status: :unprocessable_entity
    end
  end
  
  private 
  def set_order
    @order = Order.find_by(id: params[:id])
    unless @order
      render json: {error: "Order not found"}, status: :not_found #404 
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

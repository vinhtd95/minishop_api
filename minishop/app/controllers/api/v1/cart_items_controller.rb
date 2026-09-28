@order = current_user.orders.find_by(id: params[:id]) class Api::V1::CartItemsController < Api::V1::BaseController
  before_action :authenticate_api_user!
  before_action :set_cart
  before_action :set_cart_item, only: [:update, :destroy]

  # POST /api/v1/cart/items
  def create
    product = Product.find_by(id: params[:product_id])
    return render json: { error: "Product not found" }, status: :not_found unless product

    quantity = (params[:quantity] || 1).to_i
    return render json: { error: "Quantity must be greater than 0" }, status: :unprocessable_entity if quantity <= 0

    #Cộng dồn quantity nếu có sp trong giỏ 
    @cart_item = @cart.cart_items.find_or_initialize_by(product_id: product.id)
    @cart_item.quantity = (@cart_item.quantity || 0) + quantity

    if @cart_item.save
      render json: format_cart_response(@cart), status: :created
    else
      render json: { errors: @cart_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/cart/items/:id
  def update
    quantity = params[:quantity].to_i
    @cart_item.update(quantity: quantity)
    render json: format_cart_response(@cart), status: :ok
  end

  # DELETE /api/v1/cart/items/:id
  def destroy
    @cart_item.destroy
    render json: format_cart_response(@cart), status: :ok
  end

  private
  def set_cart
    @cart = current_user.cart || current_user.create_cart!
  end

  def set_cart_item
    # Lọc item qua giỏ hàng của chính user hiện tại.
    # Phải tìm sản phẩm trong chính giỏ hàng của mình -> @cart.cart_items 
    @cart_item = @cart.cart_items.find_by(id: params[:id])

    unless @cart_item
      render json: { error: "Cart item not found" }, status: :not_found
    end
  end

  def format_cart_response(cart)
    {
      items: cart.cart_items.includes(:product).map do |item|
        price_cents = ((item.product.price || 0) * 100).to_i
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
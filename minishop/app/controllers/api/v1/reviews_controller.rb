class Api::V1::ReviewsController < Api::V1::BaseController
  before_action :authenticate_api_user!, only: [:create]
  before_action :set_product

  # GET /api/v1/products/:id/reviews
  def index
    # Lấy danh sách order_items đã đánh giá (score khác nil)
    reviewed_items = @product.order_items.includes(order: :user).where.not(score: nil).order(updated_at: :desc)

    render json: {
      average_rating: @product.average_rating,
      reviews_count: @product.reviews_count,
      reviews: reviewed_items.map do |item|
        {
          id: item.id,
          user_name: item.order&.user&.email&.split('@')&.first,
          score: item.score,
          feedback: item.feedback,
          created_at: item.updated_at
        }
      end
    }, status: :ok
  end

  # POST /api/v1/products/:id/reviews
  def create
    # 1. Kiem tra user da mua san pham nay chua, neu chua mua -> chua duoc danh gia
    has_purchased = OrderItem.joins(:order).where(orders: { user_id: current_user.id }).exists?(product_id: @product.id)

    unless has_purchased
      return render json: { error: "Forbidden: You must purchase this product to review it" }, status: :forbidden
    end

    # 2. Tìm 1 order_item chưa đánh giá (score == nil) -> Nếu không còn cái nào thì 422 Unprocessable Entity
    order_item = OrderItem.joins(:order).where(orders: { user_id: current_user.id }) .where(product_id: @product.id).find_by(score: nil)
    unless order_item
      return render json: { error: "You have already reviewed this product" }, status: :unprocessable_entity
    end

    # 3. Lưu score và feedback (Nếu score ngoài khoảng 1-5 -> model validation tự trả về error 422)
    if order_item.update(review_params)
      render json: {
        id: order_item.id,
        product_id: order_item.product_id,
        score: order_item.score,
        feedback: order_item.feedback,
        created_at: order_item.updated_at
      }, status: :created
    else
      render json: { errors: order_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_product
    # Nhận :product_id từ URL
    @product = Product.find_by(id: params[:product_id])
    unless @product
      render json: { error: "Product not found" }, status: :not_found
    end
  end

  def review_params
    params.permit(:score, :feedback)
  end
end
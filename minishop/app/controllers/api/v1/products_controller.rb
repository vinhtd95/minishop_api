class Api::V1::ProductsController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:index]
  def index 
    #query params xuat hien tren URL la q va category_id, include để giúp tăng tốc độ truy vấn 
    base_scope = Product.includes(:category).search_by_name(params[:q]).by_category(params[:category_id])

    #xử lý tham số page và per_page (default 10, max 50, min 1)
    current_page = [params[:page].to_i, 1].max
    per_page = (params[:per_page] || 10).to_i
    per_page = [[per_page, 1].max, 50].min 

    #tổng số bản ghi và tổng số trang 
    total_count = base_scope.count 
    total_pages = (total_count / per_page.to_f).ceil 

    #danh sách sản phẩm cần phân trang 
    products = base_scope.order(created_at: :asc).paginate(page: current_page, per_page: per_page)

    #tra ve meta 
    render json: {
      data: products.map{ |p| product_as_json(p)},
      meta: {
        current_page: current_page,
        total_pages: total_pages,
        total_count: total_count
      }
    }
  end

  private
  def product_as_json(product)
    {
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      category_id: product.category_id,
      category: product.category ? { id: product.category.id, name: product.category.name } : nil,
      created_at: product.created_at,
      updated_at: product.updated_at
    }
  end
end

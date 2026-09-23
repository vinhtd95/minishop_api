class Api::V1::CategoriesController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:index, :show]
  
  before_action :require_admin!, only: [:create, :update, :destroy]
  before_action :set_category, only: [:show, :update, :destroy]

  #GET /api/vi/categories
  def index 
    categories = Category.all 
    render json: categories, status: :ok
  end

  #GET /api/v1/categories/:id
  def show 
    render json: @category, status: :ok
  end

  #POST /api/v1/categories 
  def create 
    category = Category.new(category_params)
    
    if category.save 
      render json: category, status: :created 
    else
      render json: {error: category.errors}, status: :unprocessable_entity
    end
  end

  #PUT/PATCH /api/v2/categories/:id 
  def update 
    if @category.update(category_params)
      render json: @category, status: :ok
    else
      render json: {errors: @category.errors}, status: :unprocessable_entity
    end
  end

  #DELETE /api/v1/categories/:id 
  def destroy 
    @category.destroy 
  end

  private 
  def set_category 
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name)
  end
end

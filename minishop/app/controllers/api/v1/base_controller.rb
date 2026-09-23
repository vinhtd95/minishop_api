class Api::V1::BaseController < ApplicationController
  before_action :authenticate_api_user!
  attr_reader :current_user 

  private
  def authenticate_api_user!
    token = request.headers['Authorization']&.split(' ')&.last || request.headers['Authorization']
    @current_user = User.find_by(api_token: token) if token.present?

    unless @current_user
      render json: {error: "Unauthorized or invalid token"}, status: :unauthorized
    end
  end

  def require_admin! 
    unless current_user&.admin?
      render json: {error: "Forbidden"}, status: :forbidden
    end
  end
  
end

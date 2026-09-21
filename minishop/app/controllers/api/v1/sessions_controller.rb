class Api::V1::SessionsController < Api::V1::BaseController

  skip_before_action :authenticate_api_user!, only: [:create]

  #POST /api/v1/login
  def create
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password].to_s)
      render json: {
        token: user.api_token,
        user: {
          id: user.id,
          email: user.email,
          role: user.role
        }
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  #GET /api/v1/me
  def show
    render json: {
      id: current_user.id,
      email: current_user.email,
      role: current_user.role
    }, status: :ok
  end

  #POST /api/v1/logout
  def destroy
    current_user.regenerate_api_token
    render json: { message: "Logged out successfully" }, status: :ok
  end
end

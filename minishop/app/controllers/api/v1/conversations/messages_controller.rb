class Api::V1::Conversations::MessagesController < Api::V1::BaseController
  before_action :set_conversation 

  # GET /api/v1/conversations/:conversation_id/messages?page=1
  def index 
    #Pagination 
    page = [params[:page].to_i, 1].max
    per_page = (params[:per_page] || 20).to_i
    per_page = [[per_page, 1].max, 100].min
    offset = (page - 1) * per_page
    
    # Lấy các tin nhắn mới nhất (latest messages) rồi đảo lại theo thứ tự thời gian tăng dần
    messages = @conversation.messages.includes(:sender).order(created_at: :desc).offset(offset).limit(per_page).reverse
    render json: messages.map { |msg| format_message(msg) }, status: :ok
  end

  private 
  def set_conversation 
    conversation_id = params[:conversation_id] 
    @conversation = Conversation.find_by(id: conversation_id)

    unless @conversation
      return render json: {error: "Conversation not found"}, status: :not_found 
    end

    unless @conversation.participant?(current_user)
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def format_message(message)
    {
      id: message.id,
      body: message.body,
      sender_id: message.sender_id,
      sender_role: message.sender&.role,
      created_at: message.created_at
    }
  end
  
end

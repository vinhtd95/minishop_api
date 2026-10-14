class Api::V1::ConversationsController < Api::V1::BaseController
  #GET /api/v1/conversations 
  def index 
    conversations = if current_user.admin?
      Conversation.includes(:user).order(updated_at: :desc)
    else 
      current_user.conversations.order(updated_at: :desc)
    end
    render json: conversations.map { |conv| format_conversation(conv) }, status: :ok
  end

  #POST /api/v1/conversations
  def create 
    conversation = current_user.conversations.find_or_create_by(status: :open)
    render json: format_conversation(conversation), status: :created
  end
  
  private
  def format_conversation(conversation)
    {
      id: conversation.id,
      status: conversation.status,
      user_id: conversation.user_id,
      user_email: conversation.user&.email,
      admin_id: conversation.admin_id,
      created_at: conversation.created_at,
      updated_at: conversation.updated_at
    }
  end
end

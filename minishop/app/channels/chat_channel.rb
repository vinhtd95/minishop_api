class ChatChannel < ApplicationCable::Channel
  def subscribed # Gọi khi client gửi lệnh subscribe:{conversation_id}
    conversation = Conversation.find_by(id: params[:conversation_id])
    if conversation && conversation.participant?(current_user)
      stream_from "conversation_#{conversation.id}"
    else 
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  def speak(data)
    conversation = Conversation.find_by(id: data["conversation_id"])
    return unless conversation && conversation.participant?(current_user)

    message = conversation.messages.build(
      sender: current_user,
      body: data["body"]
    )

    if message.save 
      ActionCable.server.broadcast(
        "conversation_#{conversation.id}",
        {
          id: message.id,
          body: message.body, 
          sender_id: message.sender_id,
          sender_role: current_user.role,
          created_at: message.created_at
        }
      )
    end
  end
end

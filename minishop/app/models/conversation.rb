class Conversation < ApplicationRecord
  belongs_to :user
  belongs_to :admin, class_name: "User", optional: true
  has_many :messages, dependent: :destroy
  enum :status, { open: 0, closed: 1 }, default: :open

  def participant?(current_user)
    return false unless current_user
    current_user.admin? || user_id == current_user.id
  end
end

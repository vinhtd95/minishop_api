class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: "User"

  validates :body, presence: true
end

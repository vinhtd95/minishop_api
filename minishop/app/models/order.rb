class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  enum :status, {pending: 0, paid: 1, shipped: 2, delivered: 3, cancelled: 4}, default: :pending

  validates :total_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  VALID_TRANSITIONS = {
    "pending"   => %w[shipped cancelled],
    "shipped"   => %w[delivered],
    "delivered" => [],
    "cancelled" => []
  }.freeze

  def valid_transition_to?(new_status)
    VALID_TRANSITIONS[status]&.include?(new_status.to_s)
  end
end

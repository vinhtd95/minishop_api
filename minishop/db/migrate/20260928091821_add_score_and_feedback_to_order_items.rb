class AddScoreAndFeedbackToOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :order_items, :score, :integer
    add_column :order_items, :feedback, :text
  end
end

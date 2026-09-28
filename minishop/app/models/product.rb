class Product < ApplicationRecord
  belongs_to :category, optional: true 
  has_many :order_items
  #tim kiem theo ten 
  scope :search_by_name, ->(q){
    where("name LIKE ?", "%#{q}%") if q.present?
  }

  #loc theo category_id 
  scope :by_category, ->(category_id) {
    where(category_id: category_id) if category_id.present?
  }

  #paginate
  scope :paginate, ->(page:, per_page:) {
    page = [page.to_i, 1].max
    offset = (page - 1) * per_page
    limit(per_page).offset(offset) #~ LIMIT per_page OFFSET offset
  }

  #average_rating 
  def average_rating 
    reviewed_items = self.order_items.where.not(score: nil)
    if reviewed_items.empty?
      return 0.0
    end
    average_score = reviewed_items.average(:score)
    average_score.to_f.round(1)
  end

  #count review
  def review_count 
    reviewed_items = self.order_items.where.not(score: nil)
    total_count = reviewed_items.count 
    return total_count 
  end
end


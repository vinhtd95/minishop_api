class Product < ApplicationRecord
  belongs_to :category, optional: true 

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

end

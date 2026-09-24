# db/seeds.rb

puts "=== Clearing old data ==="
Product.destroy_all
Category.destroy_all
User.destroy_all

puts "=== Creating Users ==="
# Customer
customer = User.find_or_create_by!(email: "test@example.com") do |user|
  user.password = "password123"
  user.role = :customer
end

# Admin
admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = "admin123"
  user.role = :admin
end

puts "=== Creating Supermarket & Fashion Categories ==="
cat_clothes  = Category.create!(name: "Quần áo & Thời trang")
cat_drinks   = Category.create!(name: "Đồ uống & Giải khát")
cat_snacks   = Category.create!(name: "Bánh kẹo & Ăn vặt")
cat_personal = Category.create!(name: "Hóa mỹ phẩm & Chăm sóc cá nhân")
cat_empty    = Category.create!(name: "Gia dụng & Đời sống") # Dùng để test Category không có sản phẩm

puts "=== Creating Products ==="

# 1. Danh mục QUẦN ÁO & THỜI TRANG (Phục vụ test tìm kiếm 'shirt', 'Shirt', 'SHIRT' case-insensitive)
Product.create!([
  { name: "Áo thun nam Classic T-Shirt", description: "Áo thun cotton 100% thoáng mát", price: 15.99, category: cat_clothes },
  { name: "Áo sơ mi công sở Oxford SHIRT", description: "Sơ mi dài tay chống nhăn", price: 29.50, category: cat_clothes },
  { name: "Áo Polo Nam Sport Shirt", description: "Áo polo thể thao co giãn 4 chiều", price: 22.00, category: cat_clothes },
  { name: "Quần Jeans Slim Fit", description: "Quần denim xanh thời trang", price: 39.99, category: cat_clothes },
  { name: "Áo khoác Blazer nữ", description: "Thích hợp đi làm và đi chơi", price: 45.00, category: cat_clothes },
  { name: "Áo Hoodie Fleece Unisex", description: "Áo nỉ nón nỉ ấm áp mùa đông", price: 32.50, category: cat_clothes }
])

# 2. Danh mục ĐỒ UỐNG & GIẢI KHÁT
Product.create!([
  { name: "Sữa tươi tiệt trùng Vinamilk 1L", description: "Sữa tươi nguyên chất 100%", price: 2.50, category: cat_drinks },
  { name: "Nước ngọt Coca-Cola 320ml", description: "Lốc 6 lon giải khát", price: 4.20, category: cat_drinks },
  { name: "Cà phê hòa tan Trung Nguyên G7", description: "Hộp 21 gói đậm đà", price: 3.80, category: cat_drinks },
  { name: "Trà xanh C2 hương chanh 455ml", description: "Chai giải nhiệt mùa hè", price: 0.60, category: cat_drinks }
])

# 3. Danh mục BÁNH KẸO & ĂN VẶT
Product.create!([
  { name: "Snack khoai tây Lay's vị Tự Nhiên", description: "Gói lớn 95g giòn rụm", price: 1.20, category: cat_snacks },
  { name: "Bánh ChocoPie Orion", description: "Hộp 12 cái phủ socola", price: 3.50, category: cat_snacks },
  { name: "Kẹo dẻo Haribo Goldbears", description: "Gói 80g nhập khẩu", price: 1.80, category: cat_snacks }
])

# 4. Danh mục HÓA MỸ PHẨM
Product.create!([
  { name: "Dầu gội Clear Bạc Hà 630g", description: "Sạch gàu mát lạnh", price: 8.90, category: cat_personal },
  { name: "Sữa tắm Lifebuoy Bảo Vệ Vượt Trội", description: "Chai 850g diệt khuẩn", price: 7.50, category: cat_personal }
])

# 5. Tạo thêm các sản phẩm phụ để tổng số lượng > 20 sản phẩm (phục vụ test phân trang page=1, page=2, page=3)
10.times do |i|
  Product.create!(
    name: "Sản phẩm siêu thị #{i + 1}",
    description: "Sản phẩm bổ sung dùng cho việc test phân trang (pagination)",
    price: (1.0 + i * 1.5).round(2),
    category: [cat_clothes, cat_drinks, cat_snacks, cat_personal].sample
  )
end

puts "=== Seeds loaded successfully! ==="
puts "Customer: test@example.com / password123"
puts "Admin:    admin@example.com / admin123"
puts "Total Users: #{User.count}"
puts "Total Categories: #{Category.count}"
puts "Total Products: #{Product.count}"
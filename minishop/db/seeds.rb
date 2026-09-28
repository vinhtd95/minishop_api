# db/seeds.rb

puts "=== Clearing old data ==="
# Dọn dẹp bảng theo thứ tự để không dính ràng buộc khóa ngoại
CartItem.destroy_all if defined?(CartItem)
Cart.destroy_all if defined?(Cart)
Product.destroy_all
Category.destroy_all
User.destroy_all

puts "=== Creating Users ==="
# Customer test (mặc định)
customer = User.find_or_create_by!(email: "test@example.com") do |user|
  user.password = "password123"
  user.role = :customer
end

# Customer thứ 2 (dùng để test case bảo mật Feature 5: User A không xem/sửa được cart của User B)
customer2 = User.find_or_create_by!(email: "customer2@example.com") do |user|
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
cat_empty    = Category.create!(name: "Gia dụng & Đời sống")

puts "=== Creating Products ==="

p1 = Product.create!(name: "Áo thun nam Classic T-Shirt", description: "Áo thun cotton 100% thoáng mát", price: 15.99, category: cat_clothes)
p2 = Product.create!(name: "Áo sơ mi công sở Oxford SHIRT", description: "Sơ mi dài tay chống nhăn", price: 29.50, category: cat_clothes)
p3 = Product.create!(name: "Áo Polo Nam Sport Shirt", description: "Áo polo thể thao co giãn 4 chiều", price: 22.00, category: cat_clothes)
p4 = Product.create!(name: "Quần Jeans Slim Fit", description: "Quần denim xanh thời trang", price: 39.99, category: cat_clothes)
p5 = Product.create!(name: "Áo khoác Blazer nữ", description: "Thích hợp đi làm và đi chơi", price: 45.00, category: cat_clothes)
p6 = Product.create!(name: "Áo Hoodie Fleece Unisex", description: "Áo nỉ nón nỉ ấm áp mùa đông", price: 32.50, category: cat_clothes)

p7 = Product.create!(name: "Sữa tươi tiệt trùng Vinamilk 1L", description: "Sữa tươi nguyên chất 100%", price: 2.50, category: cat_drinks)
p8 = Product.create!(name: "Nước ngọt Coca-Cola 320ml", description: "Lốc 6 lon giải khát", price: 4.20, category: cat_drinks)
p9 = Product.create!(name: "Cà phê hòa tan Trung Nguyên G7", description: "Hộp 21 gói đậm đà", price: 3.80, category: cat_drinks)

Product.create!([
  { name: "Snack khoai tây Lay's vị Tự Nhiên", description: "Gói lớn 95g giòn rụm", price: 1.20, category: cat_snacks },
  { name: "Bánh ChocoPie Orion", description: "Hộp 12 cái phủ socola", price: 3.50, category: cat_snacks },
  { name: "Dầu gội Clear Bạc Hà 630g", description: "Sạch gàu mát lạnh", price: 8.90, category: cat_personal }
])

# Sản phẩm phụ test phân trang
10.times do |i|
  Product.create!(
    name: "Sản phẩm siêu thị #{i + 1}",
    description: "Sản phẩm bổ sung dùng cho việc test phân trang (pagination)",
    price: (1.0 + i * 1.5).round(2),
    category: [cat_clothes, cat_drinks, cat_snacks, cat_personal].sample
  )
end

puts "=== Creating Seed Cart & Cart Items (Feature 5) ==="
# Khởi tạo giỏ hàng cho customer test@example.com
cart = Cart.create!(user: customer)

# Thêm sẵn 2 sản phẩm vào giỏ để test API GET /api/v1/cart
CartItem.create!(cart: cart, product: p1, quantity: 2) # 2 x 15.99 = 31.98 -> 3198 cents
CartItem.create!(cart: cart, product: p8, quantity: 1) # 1 x 4.20  = 4.20  -> 420 cents

# Khởi tạo giỏ hàng cho customer2@example.com (Dùng để test tính năng bảo mật 404)
cart2 = Cart.create!(user: customer2)
CartItem.create!(cart: cart2, product: p2, quantity: 1)

puts "=== Seeds loaded successfully! ==="
puts "Customer 1: test@example.com / password123 (Cart ID: #{cart.id})"
puts "Customer 2: customer2@example.com / password123 (Cart ID: #{cart2.id})"
puts "Admin:      admin@example.com / admin123"
puts "Total Users: #{User.count}"
puts "Total Categories: #{Category.count}"
puts "Total Products: #{Product.count}"
puts "Total Carts: #{Cart.count}"
puts "Total Cart Items: #{CartItem.count}"
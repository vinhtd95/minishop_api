# Customer
User.find_or_create_by!(email: "test@example.com") do |user|
  user.password = "password123"
  user.role = :customer
end

# Admin
User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = "admin123"
  user.role = :admin
end

puts "=== Seeds loaded successfully! ==="
puts "Customer: test@example.com / password123"
puts "Admin:    admin@example.com / admin123"
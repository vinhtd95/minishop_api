User.find_or_create_by!(email: "admin@example.com") do |user|
  user.password = "admin123"
  user.role = :admin
end
puts "Seeded Admin: admin@example.com / admin123"
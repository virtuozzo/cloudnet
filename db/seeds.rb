# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

admin = User.find_or_create_by(email: 'admin@cloud.net') do |u|
  u.full_name = 'Cloud Admin'
  u.password = 'adminpassword'
  u.admin = true
end

user = User.find_or_create_by(email: 'user@cloud.net') do |u|
  u.full_name = 'Cloud User'
  u.password = 'password'
  u.admin = false
end

admin.confirm! unless admin.confirmed?
user.confirm! unless user.confirmed?

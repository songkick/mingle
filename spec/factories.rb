Factory.define :artist do |a|
end

Factory.sequence :title do |n|
  "Title #{n}"
end

Factory.define :post do |p|
  p.title Factory.next(:title)
end

Factory.define :user do |u|
  u.username 'Tunch'
end


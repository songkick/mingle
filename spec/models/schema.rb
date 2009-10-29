ActiveRecord::Schema.define do
  create_table :artists, :force => true do |t|
    t.string :name
  end
  
  create_table :users, :force => true do |t|
    t.string :username
    t.string :first_name
  end
end


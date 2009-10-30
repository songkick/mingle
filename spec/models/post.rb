class Post < ActiveRecord::Base
  belongs_to :user
  
  handle_merge do |key, my_value, their_value|
    key == :author ? their_value : my_value
  end
end


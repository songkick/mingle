class Post < ActiveRecord::Base
  belongs_to :user
  
  merge_strategy do |key, my_value, their_value|
    key == :author ? their_value : my_value
  end
end


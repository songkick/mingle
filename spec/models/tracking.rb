class Tracking < ActiveRecord::Base
  belongs_to :fan, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :artist
end


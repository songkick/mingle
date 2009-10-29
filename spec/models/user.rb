class User < ActiveRecord::Base
  can_be_merged
  
  validates_exclusion_of :username, :in => %w[admin]
end


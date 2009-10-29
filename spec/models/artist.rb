class Artist < ActiveRecord::Base
  has_many :trackings
  has_many :fans, :through => :trackings
end


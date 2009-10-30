class User < ActiveRecord::Base
  validates_exclusion_of :username, :in => %w[admin]
  
  has_many :posts
  has_and_belongs_to_many :groups
  
  has_many :trackings
  has_many :artists, :through => :trackings
  
  include Relation::Relatable
end


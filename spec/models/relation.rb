class Relation < ActiveRecord::Base
  
  belongs_to :object, :polymorphic => true
  belongs_to :subject, :polymorphic => true
  
  module Relatable
    def self.included(base)
      base.has_many :relations, :as => :object
    end
    
    def is_related_to(subject, options = {})
      self.relations << Relation.create(:object       => self,
                                        :subject      => subject,
                                        :relationship => options[:as])
    end
    
    def related_to?(subject, options = {})
      return false unless relation = relations.all.find { |r| r.subject == subject }
      return false if options[:as] and relation.relationship != options[:as]
      true
    end
  end

end


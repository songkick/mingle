module Mingle
  module Merging
    
    def merge(victim, options = {})
      raise IncompatibleTypes.new unless victim.class === self
      
      merge_attributes(victim, options)
      merge_all_associations(victim) if valid?
      
      returning(valid?) { |valid| save and victim.destroy if valid }
    end
    alias :merge_from :merge
    
    def merge_into(target)
      target.merge(self)
    end
    
    def merge_all_associations(victim)
      self.class.reflect_on_all_associations.sort { |a,b|
        a.options[:through] ?
          (b.options[:through] ? 0 : -1) :
          (b.options[:through] ? 1 : 0)
      }.each do |assoc|
        merge_association(victim, assoc.name)
      end
    end
    
    def merge_association(victim, assoc_name)
      assoc = self.class.reflect_on_association(assoc_name)
      __send__("merge_#{assoc.macro}_association", victim, assoc)
    end
    
  private
    
    def merge_attributes(victim, options)
      keepers    = Merging.extract_list(options, :keep)
      overwrites = Merging.extract_list(options, :overwrite)
      
      attributes.each do |key, value|
        next if keepers.include?(key.to_sym)
        next unless value.nil? or overwrites.include?(key.to_sym)
        write_attribute(key, victim[key])
      end
    end
    
    def merge_has_many_association(victim, assoc)
      return merge_has_many_through_association(victim, assoc) if assoc.options[:through]
      key = connection.quote_column_name(assoc.primary_key_name)
      victim.__send__(assoc.name).update_all("#{key} = #{id}", "#{key} = #{victim.id}")
    end
    
    # TODO merge join models as first-class objects
    def merge_has_many_through_association(victim, assoc)
      through     = assoc.through_reflection
      foreign_key = assoc.association_foreign_key
      ids         = __send__(through.name).map { |t| t.__send__(foreign_key) }
      klass       = Kernel.const_get(through.class_name)
      
      primary_key = connection.quote_column_name(through.primary_key_name)
      foreign_key = connection.quote_column_name(foreign_key)
      
      klass.destroy_all("#{primary_key} = #{victim.id} AND #{foreign_key} IN (#{ids * ','})")
    end
    
    def merge_has_and_belongs_to_many_association(victim, assoc)
      join_table  = connection.quote_table_name(assoc.options[:join_table])
      primary_key = connection.quote_column_name(assoc.primary_key_name)
      foreign_key = connection.quote_column_name(assoc.association_foreign_key)
      
      connection.execute <<-SQL
        DELETE FROM #{join_table}
        WHERE #{primary_key} = #{victim.id}
        AND #{foreign_key} IN (
          SELECT #{foreign_key}
          FROM #{join_table}
          WHERE #{primary_key} = #{id}
        )
      SQL
      
      connection.execute <<-SQL
        UPDATE #{join_table}
        SET #{primary_key} = #{id}
        WHERE #{primary_key} = #{victim.id}
      SQL
    end
    
    def self.extract_list(hash, key)
      list = hash[key] || []
      [list].flatten
    end
    
  end
end


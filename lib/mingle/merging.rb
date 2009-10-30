module Mingle
  module Merging
    
    def merge(victim, options = {}, &strategy)
      raise IncompatibleTypes.new unless victim.class === self
      
      merge_attributes(victim, options, &strategy)
      merge_all_associations(victim, options, &strategy) if valid?
      
      returning(valid?) { |valid| save and victim.destroy if valid }
    end
    alias :merge_from :merge
    
    def merge_into(target)
      target.merge(self)
    end
    
    def merge_all_associations(victim, options = {}, &strategy)
      self.class.reflect_on_all_associations.sort { |a,b|
        a.options[:through] ?
          (b.options[:through] ? 0 : -1) :
          (b.options[:through] ? 1 : 0)
      }.each do |assoc|
        merge_association(victim, assoc.name, options, &strategy)
      end
    end
    
    def merge_association(victim, assoc_name, options = {}, &strategy)
      assoc = self.class.reflect_on_association(assoc_name)
      __send__("merge_#{assoc.macro}_association", victim, assoc, options, &strategy)
    end
    
  private
    
    def merge_attributes(victim, options = {}, &strategy)
      references   = self.class.reflect_on_all_associations.select { |assoc| assoc.macro == :belongs_to }
      foreign_keys = references.map { |assoc| assoc.association_foreign_key.to_sym }
      keepers      = Merging.extract_list(options, :keep)
      overwrites   = Merging.extract_list(options, :overwrite)
      strategy     = strategy || self.class.merge_strategy
      
      attributes.each do |key, my_value|
        key, their_value = key.to_sym, victim[key]
        next if foreign_keys.include?(key)
        
        if strategy
          write_attribute(key, strategy.call(key, my_value, their_value))
        else
          next if keepers.include?(key)
          write_attribute(key, their_value) if my_value.nil? or overwrites.include?(key)
        end
      end
    end
    
    def merge_belongs_to_association(victim, assoc, options = {}, &strategy)
      foreign_key = assoc.association_foreign_key.to_sym
      keepers     = Merging.extract_list(options, :keep)
      overwrites  = Merging.extract_list(options, :overwrite)
      strategy    = strategy || self.class.merge_strategy
      
      my_value, their_value = self[foreign_key], victim[foreign_key]
      
      if strategy
        my_value, their_value = __send__(assoc.name), victim.__send__(assoc.name)
        __send__("#{assoc.name}=", result = strategy.call(assoc.name, my_value, their_value))
      else
        if not keepers.include?(assoc.name) and (my_value.nil? or overwrites.include?(foreign_key))
          write_attribute(foreign_key, their_value)
        end
      end
    end
    
    def merge_has_many_association(victim, assoc, options = {}, &strategy)
      return merge_has_many_through_association(victim, assoc) if assoc.options[:through]
      key = connection.quote_column_name(assoc.primary_key_name)
      victim.__send__(assoc.name).update_all("#{key} = #{id}", "#{key} = #{victim.id}")
    end
    
    # TODO merge join models as first-class objects
    def merge_has_many_through_association(victim, assoc, options = {}, &strategy)
      through     = assoc.through_reflection
      foreign_key = assoc.association_foreign_key
      ids         = __send__(through.name).map { |t| t.__send__(foreign_key) }
      klass       = Kernel.const_get(through.class_name)
      
      primary_key = connection.quote_column_name(through.primary_key_name)
      foreign_key = connection.quote_column_name(foreign_key)
      
      klass.destroy_all("#{primary_key} = #{victim.id} AND #{foreign_key} IN (#{ids * ','})")
    end
    
    def merge_has_and_belongs_to_many_association(victim, assoc, options = {}, &strategy)
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


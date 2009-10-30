module Mingle
  module Merging
    
    def self.extract_list(hash, key)
      list = hash[key] || []
      [list].flatten
    end
    
    def self.synthesize_merge_strategy(options, strategy)
      keepers    = extract_list(options, :keep)
      overwrites = extract_list(options, :overwrite)
      
      lambda do |key, my_value, their_value|
        if keepers.include?(key)
          my_value
        elsif overwrites.include?(key)
          their_value
        elsif strategy
          strategy.call(key, my_value, their_value)
        else
          my_value.nil? ? their_value : my_value
        end
      end
    end
    
    def merge(victim, options = {}, &strategy)
      raise IncompatibleTypes.new unless victim.class === self
      
      strategy = Merging.synthesize_merge_strategy(options, strategy || self.class.merge_strategy)
      merge_attributes(victim, &strategy)
      merge_all_associations(victim, &strategy) if valid?
      
      returning(valid?) { |valid| save and victim.destroy if valid }
    end
    alias :merge_from :merge
    
    def merge_into(target)
      target.merge(self)
    end
    
    def merge_all_associations(victim, &strategy)
      self.class.reflect_on_all_associations.sort { |a,b|
        a.options[:through] ?
          (b.options[:through] ? 0 : -1) :
          (b.options[:through] ? 1 : 0)
      }.each do |assoc|
        merge_association(victim, assoc.name, &strategy)
      end
    end
    
    def merge_association(victim, assoc_name, &strategy)
      assoc = self.class.reflect_on_association(assoc_name)
      __send__("merge_#{assoc.macro}_association", victim, assoc, &strategy)
    end
    
  private
    
    def merge_attributes(victim, &strategy)
      references   = self.class.reflect_on_all_associations.select { |assoc| assoc.macro == :belongs_to }
      foreign_keys = references.map { |assoc| assoc.association_foreign_key.to_sym }
      
      attributes.each do |key, my_value|
        key, their_value = key.to_sym, victim[key]
        next if foreign_keys.include?(key)
        write_attribute(key, strategy.call(key, my_value, their_value))
      end
    end
    
    def merge_belongs_to_association(victim, assoc, &strategy)
      foreign_key = assoc.association_foreign_key.to_sym
      my_value    = __send__(assoc.name)
      their_value = victim.__send__(assoc.name)
      __send__("#{assoc.name}=", strategy.call(assoc.name, my_value, their_value))
    end
    
    def merge_has_many_association(victim, assoc, &strategy)
      return merge_has_many_through_association(victim, assoc) if assoc.options[:through]
      
      mine   = __send__(assoc.name)
      theirs = victim.__send__(assoc.name)
      klass  = Kernel.const_get(assoc.class_name)
      key    = assoc.primary_key_name
      
      if detect_duplicates = klass.merge_if
        theirs.each do |associated_object|
          if dupe = mine.select { |record| detect_duplicates.call(record, associated_object) }.first
            dupe.merge(associated_object)
          else
            associated_object.update_attribute(key, id)
          end
        end
      else
        theirs.update_all("#{connection.quote_column_name key} = #{id}")
      end
    end
    
    # TODO merge join models as first-class objects
    def merge_has_many_through_association(victim, assoc, &strategy)
      through     = assoc.through_reflection
      foreign_key = assoc.association_foreign_key
      ids         = __send__(through.name).map { |t| t.__send__(foreign_key) }
      klass       = Kernel.const_get(through.class_name)
      
      primary_key = connection.quote_column_name(through.primary_key_name)
      foreign_key = connection.quote_column_name(foreign_key)
      
      klass.destroy_all("#{primary_key} = #{victim.id} AND #{foreign_key} IN (#{ids * ','})")
    end
    
    def merge_has_and_belongs_to_many_association(victim, assoc, &strategy)
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
    
  end
end


module Mingle
  module Merging
    
    def merge(victim, options = {})
      raise IncompatibleTypes.new unless victim.class === self
      
      keepers    = Merging.extract_list(options, :keep)
      overwrites = Merging.extract_list(options, :overwrite)
      
      attributes.each do |key, value|
        next if keepers.include?(key.to_sym)
        next unless value.nil? or overwrites.include?(key.to_sym)
        write_attribute(key, victim[key])
      end
      
      merge_all_associations(victim) if valid?
      
      returning(valid?) { |valid| save and victim.destroy if valid }
    end
    
    def merge_all_associations(victim)
      self.class.reflect_on_all_associations.each do |assoc|
        merge_association(victim, assoc.name)
      end
    end
    
    def merge_association(victim, assoc_name)
      assoc = self.class.reflect_on_association(assoc_name)
      __send__("merge_#{assoc.macro}_association", victim, assoc)
    end
    
  private
    
    def merge_has_many_association(victim, assoc)
      key = connection.quote_column_name(assoc.primary_key_name)
      connection.execute <<-SQL, "#{assoc.class_name} Update"
        UPDATE #{assoc.quoted_table_name}
        SET #{key} = #{id}
        WHERE #{key} = #{victim.id}
      SQL
    end
    
    def self.extract_list(hash, key)
      list = hash[key] || []
      [list].flatten
    end
    
  end
end


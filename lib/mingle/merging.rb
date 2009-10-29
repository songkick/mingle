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
      
      returning(valid?) { |valid| save and victim.destroy if valid }
    end
    
    def self.extract_list(hash, key)
      list = hash[key] || []
      [list].flatten
    end
    
  end
end


module Mingle
  module Merging
    
    def merge(record, options = {})
      raise IncompatibleTypes.new unless record.class === self
      
      keepers    = Merging.extract_list(options, :keep)
      overwrites = Merging.extract_list(options, :overwrite)
      
      attributes.each do |key, value|
        next if keepers.include?(key.to_sym)
        next unless value.nil? or overwrites.include?(key.to_sym)
        write_attribute(key, record[key])
      end
      save
    end
    
    def self.extract_list(hash, key)
      (hash[key] || []).to_a
    end
    
  end
end


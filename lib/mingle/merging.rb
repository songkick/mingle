module Mingle
  module Merging
    
    def merge(record, options = {})
      raise IncompatibleTypes.new unless record.class === self
      keepers = (options[:keep] || []).to_a
      attributes.each do |key, value|
        next if !value.nil? or keepers.include?(key.to_sym)
        write_attribute(key, record[key])
      end
      save
    end
    
  end
end


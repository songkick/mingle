module Mingle
  module Merging
    
    def merge(record)
      attributes.each do |key, value|
        write_attribute(key, record[key]) if value.nil?
      end
      save
    end
    
  end
end


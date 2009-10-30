module Mingle
  module Macros
    
    def handle_merge(&strategy)
      write_inheritable_attribute(:merge_strategy, strategy)
    end
    
  end
end


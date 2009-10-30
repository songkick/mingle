module Mingle
  module Macros
    
    def merge_strategy(&strategy)
      block_given? ?
        write_inheritable_attribute(:merge_strategy, strategy) :
        read_inheritable_attribute(:merge_strategy)
    end
    
  end
end


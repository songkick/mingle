module Mingle
  module Macros
    
    def merge_strategy(&strategy)
      block_given? ?
        write_inheritable_attribute(:merge_strategy, strategy) :
        read_inheritable_attribute(:merge_strategy)
    end
    
    def merge_if(&detector)
      block_given? ?
        write_inheritable_attribute(:merge_if, detector) :
        read_inheritable_attribute(:merge_if)
    end
    
  end
end


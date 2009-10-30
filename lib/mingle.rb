require 'active_record'

require 'mingle/macros'
require 'mingle/merging'

module Mingle
  VERSION = '0.1.0'
  
  class IncompatibleTypes < StandardError; end
end

class ActiveRecord::Base
  extend Mingle::Macros
  include Mingle::Merging
end


require 'active_record'

require 'mingle/macros'
require 'mingle/merging'

module Mingle
  VERSION = '0.1.0'
end

ActiveRecord::Base.extend Mingle::Macros


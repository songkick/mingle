require 'active_record'

%w[macros merging].each do |file|
  require File.join(File.dirname(__FILE__), 'mingle', file)
end

module Mingle
  VERSION = '0.1.0'
  
  class IncompatibleTypes < StandardError; end
end

class ActiveRecord::Base
  extend Mingle::Macros
  include Mingle::Merging
end


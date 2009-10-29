require 'factory_girl'
require File.dirname(__FILE__) + '/../lib/mingle'

ActiveRecord::Base.establish_connection :adapter  => 'sqlite3',
                                        :database => 'spec/test.db'

%w[schema artist user].each do |file|
  require File.dirname(__FILE__) + '/models/' + file
end


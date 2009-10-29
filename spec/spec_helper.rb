require 'factory_girl'
require 'database_cleaner'

require 'lib/mingle'

ActiveRecord::Base.establish_connection :adapter  => 'sqlite3',
                                        :database => 'spec/test.db'

ActiveRecord::Base.logger = Logger.new('spec/test.log')

%w[schema artist user].each do |file|
  require 'models/' + file
end

Spec::Runner.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) { DatabaseCleaner.start }
  config.after(:each)  { DatabaseCleaner.clean }
end


require 'factory_girl'
require 'pry'
require 'simplecov'
require 'sidekiq'
require 'sidekiq/testing'

SimpleCov.start do
  coverage_dir 'tmp/coverage'
end

require 'rekiq'

# configure sidekiq for testing
Sidekiq::Testing.fake!
Sidekiq::Logging.logger = nil

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:each) do
    Sidekiq::Worker.clear_all
    Redis.new.flushdb
  end

  config.after(:suite) do
    Sidekiq::Worker.clear_all
    Redis.new.flushdb
  end
end

# configure factory girl
FactoryGirl.definition_file_paths = %w{./spec/factories}
FactoryGirl.find_definitions
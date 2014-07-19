if ENV['CODECLIMATE_REPO_TOKEN'].nil?
  require 'simplecov'
  SimpleCov.start do
    coverage_dir 'tmp/coverage'
  end
else
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

require 'factory_girl'
require 'pry'
require 'sidekiq'
require 'sidekiq/testing'
require 'rekiq'

# configure sidekiq for testing
Sidekiq::Testing.fake!
Sidekiq::Logging.logger = nil

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  config.after(:suite) do
    Sidekiq::Worker.clear_all
  end
end

# configure factory girl
FactoryGirl.definition_file_paths = %w{./spec/factories}
FactoryGirl.find_definitions
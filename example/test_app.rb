# install gem and run with:
# bundle exec sidekiq -C example/sidekiq.yml -r ./example/test_app.rb

require 'ice_cube'
require 'sidekiq'
require 'rekiq'
require 'pry'

# define sidekiq worker as you normally would
class TestWorker1
  include Sidekiq::Worker

  sidekiq_options queue: "rekiq_test_worker",
                  retry: 3,
                  rekiq_cancel_method: :cancel

  def perform(arg1, arg2)
    puts "\nhello from TestWorker1, arg1 is #{arg1}, arg2 is #{arg2} " \
         "scheduled work time was #{scheduled_work_time}\n\n"
  end

  def cancel(arg1)
    puts "\ncancel method invoked with arg #{arg1}\n\n"
  end
end

# create ice cube schedule
schedule = IceCube::Schedule.new(Time.now) do |s|
    s.rrule IceCube::Rule.minutely
  end

# invoke method
TestWorker1.perform_recurringly(
    schedule,
    ['Rekiq', 'ola', '!!!'],
    { 'complex' => { 'hash' => 'woot!' } }
  ) do |config|
    config.rekiq_cancel_args 1
  end
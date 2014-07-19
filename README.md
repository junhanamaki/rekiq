# Rekiq

Recurring worker extension for Sidekiq.

## Overview

Rekiq extends Sidekiq and adds functionality to schedule recurring workers.

In pratical means, rekiq allows you to schedule a worker to repeat the same
work friday at 23:00, for example.

## Requirements

Tested with:

  * Ruby version 2.1.1
  * Sidekiq 3.2.1
  * ice_cube 0.12.0

May work with other versions.

## Installation

Add this line to your application's Gemfile:

    gem 'rekiq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rekiq

## Usage

Since rekiq won't require sidekiq by itself, you must already have sidekiq
required before requiring rekiq (error will be raised if not). Order matters
because rekiq will extend Sidekiq::Worker and add its own sidekiq middleware:

    require 'sidekiq'
    require 'rekiq'

After requiring rekiq, your sidekiq worker class will have a new method called
'perform_reccuringly', used to schedule recurring workers and receives a
schedule object (more about that later), followed by the worker
arguments (much like Sidekiq's 'perform_at'). An example:

    # define worker as normal
    class ExampleWorker
      include Sidekiq::Worker

      def perform(arg1, arg2)
        # Do some work
      end
    end

    # initialize worker
    ExampleWorker.perform_reccuringly(schedule, worker_arg1, worker_arg2)

Now what is this schedule object? It's an object that calculate the time
at which the worker should do its work, as such must respond to method:

    schedule.next_occurrence(time)

Where argument time is an instance of Time, and returns also a Time. You can
use ice_cube (https://github.com/seejohnrun/ice_cube) for this, which is easy
to use and its the one used to test. Either way since rekiq does not have any
dependency to it any object with the following behavior will do:

    * schedule object must respond to method next_occurence(time)
    * schedule object must be serializable with YAML::dump, and deserializable
      with YAML::load

So back to out example, let's complete it by creating an ice_cube schedule:

    # create schedule for worker to repeat every friday
    # at 11pm
    schedule = IceCube::Schedule.new do |s|
        s.rrule IceCube::Rule.weekly.day(:friday).hour_of_day(23)
      end

    # inialize worker with schedule and arguments
    ExampleWorker.perform_reccuringly(schedule, worker_arg1, worker_arg2)

## Implementation



## Contributing

1. Fork it ( https://github.com/[my-github-username]/rekiq/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

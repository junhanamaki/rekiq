# Rekiq

[![Build Status](https://travis-ci.org/junhanamaki/rekiq.svg?branch=master)](https://travis-ci.org/junhanamaki/rekiq)
[![Code Climate](https://codeclimate.com/github/junhanamaki/rekiq.png)](https://codeclimate.com/github/junhanamaki/rekiq)
[![Test Coverage](https://codeclimate.com/github/junhanamaki/rekiq/coverage.png)](https://codeclimate.com/github/junhanamaki/rekiq)
[![Dependency Status](https://gemnasium.com/junhanamaki/rekiq.svg)](https://gemnasium.com/junhanamaki/rekiq)

**Rekiq is a recurring worker extension for
[Sidekiq](https://github.com/mperham/sidekiq).**

Rekiq extends Sidekiq and adds functionality to schedule recurring workers.

Sidekiq is an amazing gem that allows us delegate time consuming work to a
worker, or even to schedule a time for the worker to start. Now wouldn't it be
nice if it also allowed us to schedule a worker to do work recurringly? That's
what rekiq purposes to do.

In pratical means, rekiq allows you to schedule a worker to repeat the same
work friday at 23:00, for example.

## Requirements

Tested with:

  * Ruby version 2.1.1, 2.0.0 and 1.9.3
  * Sidekiq 3.2.1
  * ice_cube 0.12.0

## Installation

Add this line to your application's Gemfile:

    gem 'rekiq', git: 'https://github.com/junhanamaki/rekiq'

And then execute:

    $ bundle

Or compile source by hand, since for now it's not published.

## Usage

### Basics

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
use [ice_cube](https://github.com/seejohnrun/ice_cube) for this, which is the
one used for testing. Either way since rekiq does not have any dependency of
that kind any object with the following behavior will do:

  * schedule object must respond to method next_occurence(time)
  * schedule object must be serializable with YAML::dump, and deserializable
    with YAML::load

So back to out example, let's complete it by creating an ice_cube schedule:

    # create schedule for worker to repeat every friday at 11pm
    schedule = IceCube::Schedule.new do |s|
        s.rrule IceCube::Rule.weekly.day(:friday).hour_of_day(23)
      end

    # inialize worker with schedule and arguments
    ExampleWorker.perform_reccuringly(schedule, worker_arg1, worker_arg2)

### Configuration

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rekiq/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

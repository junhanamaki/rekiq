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

For example, rekiq allows you to schedule a worker to repeat the same
work every friday at 23:00.

## Requirements

Tested with:

  * ruby 2.1.1, 2.0.0 and 1.9.3
  * sidekiq 3.2.1

## Installation

Add this line to your application's Gemfile:

    gem 'rekiq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rekiq

## Basic usage

Require rekiq after sidekiq:

    require 'sidekiq'
    require 'rekiq'

We need a 'schedule' object (responsible for returning the time at which the
worker should start) which must respond to method next_occurrence and
receives one argument of type Time more at [The schedule object](https://github.com/junhanamaki/rekiq/wiki/The-schedule-object).
For our example we'll be using the gem [ice_cube](https://github.com/seejohnrun/ice_cube)
(don't forget to require it):

    # define worker as normal
    class ExampleWorker
      include Sidekiq::Worker

      def perform(arg1, arg2)
        # Do some work
      end
    end

    # create schedule for worker to repeat every friday at 2am
    schedule = IceCube::Schedule.new do |s|
        s.rrule IceCube::Rule.daily.day(:friday).hour_of_day(2)
      end

    # now just start your worker
    ExampleWorker.perform_recurringly(schedule, 'argument_1', 'argument_2')

You can use your own schedule object, configure worker to reschedule before or
after work is done, set margin, and much more! So please check
[wiki](https://github.com/junhanamaki/rekiq/wiki) for more details.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rekiq/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

require 'rekiq/validator'
require 'rekiq/configuration'

module Rekiq
  class Contract
    include Validator

    attr_accessor :schedule, :cancel_args, :addon, :schedule_post_work,
                  :work_time_shift, :work_time_tolerance, :schedule_expired

    validate :schedule,            :schedule
    validate :schedule_post_work,  :bool,    allow_nil: true
    validate :work_time_shift,     :numeric, allow_nil: true
    validate :work_time_tolerance, :numeric, allow_nil: true,
             greater_than_or_equal_to: 0
    validate :schedule_expired,    :bool,    allow_nil: true

    class << self
      def from_hash(hash)
        new \
          'schedule'            => Marshal.load(hash['s'].encode('ISO-8859-1')),
          'cancel_args'         => hash['ca'],
          'addon'               => hash['ao'],
          'schedule_post_work'  => hash['pw'],
          'work_time_shift'     => hash['ws'],
          'work_time_tolerance' => hash['wt'],
          'schedule_expired'    => hash['se']
      end
    end

    def initialize(attributes = {})
      @schedule            = attributes['schedule']
      @cancel_args         = attributes['cancel_args']
      @addon               = attributes['addon']
      @schedule_post_work  = attributes['schedule_post_work']
      @work_time_shift     = attributes['work_time_shift']
      @work_time_tolerance = attributes['work_time_tolerance']
      @schedule_expired    = attributes['schedule_expired']
    end

    def to_hash
      {}.tap do |h|
        h['s'] =
          Marshal.dump(schedule).force_encoding('ISO-8859-1').encode('UTF-8')

        h['ca'] = cancel_args         unless cancel_args.nil?
        h['ao'] = addon               unless addon.nil?
        h['pw'] = schedule_post_work  unless schedule_post_work.nil?
        h['ws'] = work_time_shift     unless work_time_shift.nil?
        h['wt'] = work_time_tolerance unless work_time_tolerance.nil?
        h['se'] = schedule_expired    unless schedule_expired.nil?
      end
    end

    def initial_work_time(from)
      from = (shift > 0 ? from - shift : from) - tolerance
      calculate_work_time(from)
    end

    def next_work_time(previous_work_time)
      from = (previous_work_time - shift) - tolerance
      calculate_work_time(from)
    end

    def schedule_post_work?
      unless schedule_post_work.nil?
        schedule_post_work
      else
        Rekiq.configuration.schedule_post_work
      end
    end

  protected

    def calculate_work_time(from)
      if schedule_expired?
        from      = schedule.next_occurrence(from)
        work_time = from.nil? ? nil : from + shift
      else
        begin
          from      = schedule.next_occurrence(from)
          work_time = from.nil? ? nil : from + shift
        end until work_time.nil? || work_time > expiration_time
      end

      work_time
    end

    def expiration_time
      Time.now - tolerance
    end

    def shift
      unless work_time_shift.nil?
        work_time_shift
      else
        Rekiq.configuration.work_time_shift
      end
    end

    def tolerance
      unless work_time_tolerance.nil?
        work_time_tolerance
      else
        Rekiq.configuration.work_time_tolerance
      end
    end

    def schedule_expired?
      unless schedule_expired.nil?
        schedule_expired
      else
        Rekiq.configuration.schedule_expired
      end
    end
  end
end
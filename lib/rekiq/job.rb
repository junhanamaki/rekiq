require 'rekiq/validator'
require 'rekiq/configuration'

module Rekiq
  class Job
    include Validator

    attr_accessor :schedule, :schedule_post_work, :work_time_shift,
                  :work_time_tolerance, :schedule_expired

    validate :schedule,            :schedule
    validate :schedule_post_work,  :bool,    allow_nil: true
    validate :work_time_shift,     :numeric, allow_nil: true
    validate :work_time_tolerance, :numeric, allow_nil: true,
             greater_than_or_equal_to: 0
    validate :schedule_expired,    :bool,    allow_nil: true

    class << self
      def from_array(array)
        new \
          'schedule'            => Marshal.load(array[0].encode('ISO-8859-1')),
          'work_time_shift'     => array[1],
          'schedule_post_work'  => array[2],
          'schedule_expired'    => array[3],
          'work_time_tolerance' => array[4]
      end
    end

    def initialize(attributes = {})
      @schedule            = attributes['schedule']
      @schedule_post_work  = attributes['schedule_post_work']
      @work_time_shift     = attributes['work_time_shift']
      @work_time_tolerance = attributes['work_time_tolerance']
      @schedule_expired    = attributes['schedule_expired']
    end

    def to_array
      [
        Marshal.dump(schedule).force_encoding('ISO-8859-1').encode('UTF-8'),
        work_time_shift,
        schedule_post_work,
        schedule_expired,
        work_time_tolerance
      ]
    end

    def next_work_time(from = Time.now)
      from_with_work_time_shift =
        if work_time_shift_val > 0
          from - work_time_shift_val
        else
          from
        end

      search_next_work_time(from_with_work_time_shift)
    end

    def next_work_time_from_work_time(from)
      from_with_work_time_shift = from - work_time_shift_val

      search_next_work_time(from_with_work_time_shift)
    end

    def schedule_post_work?
      unless schedule_post_work.nil?
        schedule_post_work
      else
        Rekiq.configuration.schedule_post_work
      end
    end

  protected

    def search_next_work_time(from)
      if schedule_expired?
        from = schedule.next_occurrence(from)
        work_time = from.nil? ? nil : from + work_time_shift_val
      else
        begin
          from = schedule.next_occurrence(from)
          work_time = from.nil? ? nil : from + work_time_shift_val
        end until work_time.nil? || work_time > expiration_time
      end

      work_time
    end

    def expiration_time
      Time.now - work_time_tolerance_val
    end

    def schedule_expired?
      unless schedule_expired.nil?
        schedule_expired
      else
        Rekiq.configuration.schedule_expired
      end
    end

    def work_time_tolerance_val
      unless work_time_tolerance.nil?
        work_time_tolerance
      else
        Rekiq.configuration.work_time_tolerance
      end
    end

    def work_time_shift_val
      unless work_time_shift.nil?
        work_time_shift
      else
        Rekiq.configuration.work_time_shift
      end
    end
  end
end
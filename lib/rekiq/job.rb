require 'yaml'
require 'rekiq/validator'
require 'rekiq/configuration'

module Rekiq
  class Job
    include Validator

    attr_accessor :schedule, :shift, :schedule_post_work, :schedule_expired,
                  :expiration_margin

    validate :schedule, :schedule
    validate :shift, :numeric, allow_nil: true
    validate :schedule_post_work, :bool, allow_nil: true
    validate :schedule_expired, :numeric, allow_nil: true
    validate :expiration_margin, :bool, allow_nil: true

    def self.from_array(array)
      attributes = {}.tap do |hash|
          hash['schedule']           = YAML::load(array[0])
          hash['shift']              = array[1]
          hash['schedule_post_work'] = array[2]
          hash['schedule_expired']   = array[3]
          hash['expiration_margin']  = array[4]
        end

      new(attributes)
    end

    def initialize(attributes = {})
      self.schedule           = attributes['schedule']
      self.shift              = attributes['shift']
      self.schedule_post_work = attributes['schedule_post_work']
      self.schedule_expired   = attributes['schedule_expired']
      self.expiration_margin  = attributes['expiration_margin']
    end

    def to_array
      [
        YAML::dump(schedule),
        shift,
        schedule_post_work,
        schedule_expired,
        expiration_margin
      ]
    end

    def next_work_time(from = Time.now)
      from_with_shift = shift_val > 0 ? from - shift_val : from

      search_next_work_time(from_with_shift)
    end

    def next_work_time_from_work_time(from)
      from_with_shift = from - shift_val

      search_next_work_time(from_with_shift)
    end

    def schedule_post_work?
      unless schedule_post_work.nil?
        schedule_post_work
      else
        Rekiq.configuration.schedule_post_work
      end
    end

  private

    def search_next_work_time(from)
      if schedule_expired?
        from = schedule.next_occurrence(from)
        work_time = from.nil? ? nil : from + shift_val
      else
        begin
          from = schedule.next_occurrence(from)
          work_time = from.nil? ? nil : from + shift_val
        end until work_time.nil? || work_time > expiration_time
      end

      work_time
    end

    def schedule_expired?
      unless schedule_expired.nil?
        schedule_expired
      else
        Rekiq.configuration.schedule_expired
      end
    end

    def expiration_margin_val
      unless expiration_margin.nil?
        expiration_margin
      else
        Rekiq.configuration.expiration_margin
      end
    end

    def shift_val
      unless shift.nil?
        shift
      else
        Rekiq.configuration.shift
      end
    end

    def expiration_time
      Time.now - expiration_margin_val
    end
  end
end
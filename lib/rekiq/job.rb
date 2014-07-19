require 'yaml'

module Rekiq
  class Job
    attr_accessor :schedule, :shift, :schedule_post_work, :schedule_expired,
                  :expiration_margin

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

    def validate!
      unless schedule.respond_to?(:next_occurrence) and
             schedule.method(:next_occurrence).arity.abs == 1
        raise InvalidConf, 'schedule object must respond to next_occurrence ' \
                           'and receive one argument of type Time'
      end

      unless shift.nil? or shift.is_a?(Numeric)
        raise InvalidConf, 'shift must be nil or numeric'
      end

      unless schedule_post_work.nil? or
             [true, false].include?(schedule_post_work)
        raise InvalidConf, 'schedule_post_work must be bool'
      end

      unless expiration_margin.nil? or
             (expiration_margin.is_a?(Numeric) and expiration_margin >= 0)
        raise InvalidConf, 'expiration_margin must be numeric and ' \
                           'greater or equal than 0'
      end

      unless schedule_expired.nil? or
             [true, false].include?(schedule_expired)
        raise InvalidConf, 'schedule_expired must be bool'
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
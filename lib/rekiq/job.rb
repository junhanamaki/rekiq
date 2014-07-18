require 'yaml'
require 'rekiq/schedule_format_validator'

module Rekiq
  class Job
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    attr_accessor :schedule, :shift, :reschedule_post_work, :schedule_expired,
                  :expiration_margin

    validates :schedule, 'rekiq::_schedule_format' => true
    validates :shift, numericality: true
    validates :reschedule_post_work, :schedule_expired,
              inclusion: { in: [true, false], allow_nil: true }
    validates :expiration_margin,
              numericality: { greater_than_or_equal_to: 0, allow_nil: true }

    def self.from_short_key_hash(hash)
      hash['schedule']             = YAML::load(hash['sch'])
      hash['shift']                = hash['sft']
      hash['reschedule_post_work'] = hash['rpw']
      hash['schedule_expired']     = hash['se']
      hash['expiration_margin']    = hash['em']

      new(hash)
    end

    def initialize(attributes = {})
      self.schedule             = attributes['schedule']
      self.shift                = attributes['shift'] || 0
      self.reschedule_post_work = attributes['reschedule_post_work']
      self.schedule_expired     = attributes['schedule_expired']
      self.expiration_margin    = attributes['expiration_margin']
    end

    def to_short_key_hash
      {
        'sch' => YAML::dump(schedule),
        'sft' => shift,
        'rpw' => reschedule_post_work,
        'se'  => schedule_expired,
        'em'  => expiration_margin
      }
    end

    def next_work_time(from = Time.now)
      shifted_from = shift > 0 ? from - shift : from

      search_next_work_time(shifted_from)
    end

    def next_work_time_from_work_time(from)
      shifted_from = from - shift

      search_next_work_time(shifted_from)
    end

    def reschedule_post_work?
      unless reschedule_post_work.nil?
        reschedule_post_work
      else
        Rekiq.configuration.reschedule_post_work
      end
    end

  private

    def search_next_work_time(from)
      if schedule_expired?
        from = schedule.next_occurrence(from)
        work_time = from.nil? ? nil : from + shift
      else
        begin
          from = schedule.next_occurrence(from)
          work_time = from.nil? ? nil : from + shift
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

    def expiration_time
      Time.now - expiration_margin_val
    end
  end
end
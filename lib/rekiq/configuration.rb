require 'rekiq/validator'

module Rekiq
  class Configuration
    include Validator

    attr_accessor :schedule_post_work, :work_time_shift, :work_time_tolerance,
                  :schedule_expired

    validate :schedule_post_work,  :bool
    validate :work_time_shift,     :numeric
    validate :work_time_tolerance, :numeric, greater_than_or_equal_to: 0
    validate :schedule_expired,    :bool

    def initialize
      # indicates if next work is scheduled after or before the worker completes
      # this is relevant when we want to guarantee that workers do not run in paralel
      # default false
      @schedule_post_work = false

      # indicates a shift, in seconds, to apply to event time returned from schedule
      # to calculate the work_time
      # default 0
      @work_time_shift = 0

      # indicates the tolerance, in seconds, for work_time relative to current time
      # default 0 and must be greater than or equal to 0
      @work_time_tolerance = 0

      # indicates if expired work_times are to be scheduled
      # a work_time is considered expired when it's before current time minus
      # work_time_tolerance
      # default false
      @schedule_expired = false
    end
  end

  class << self
    def configure
      yield configuration
      configuration.validate!
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration
      @configuration = Configuration.new
    end
  end
end
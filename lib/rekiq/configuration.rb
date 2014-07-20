require 'rekiq/validator'

module Rekiq
  class Configuration
    include Validator

    attr_accessor :shift, :schedule_post_work, :schedule_expired,
                  :expiration_margin

    validate :shift, :numeric
    validate :schedule_post_work, :bool
    validate :expiration_margin, :numeric, greater_than_or_equal_to: 0
    validate :schedule_expired, :bool

    def initialize
      # the value of the shift to apply relative to time returned by schedule
      self.shift = 0

      # if next work is scheduled after or before the worker completes
      self.schedule_post_work = false

      # indicates the margin after which a work is considered expired
      # default to 0
      self.expiration_margin = 0

      # if expired works are to be scheduled
      # an expired work is a work that has a time bellow current_time - margin
      self.schedule_expired = false
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
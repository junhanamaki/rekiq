module Rekiq
  class Configuration
    attr_accessor :shift, :schedule_post_work, :schedule_expired,
                  :expiration_margin

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

    def validate!
      unless shift.is_a?(Numeric)
        raise InvalidConf, 'shift must be numeric'
      end

      unless [true, false].include?(schedule_post_work)
        raise InvalidConf, 'schedule_post_work must be bool'
      end

      unless expiration_margin.is_a?(Numeric) and expiration_margin >= 0
        raise InvalidConf, 'expiration_margin must be numeric and ' \
                               'greater or equal than 0'
      end

      unless [true, false].include?(schedule_expired)
        raise InvalidConf, 'schedule_expired must be bool'
      end
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
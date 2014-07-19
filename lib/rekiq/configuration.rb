module Rekiq
  class Configuration
    attr_accessor :reschedule_post_work, :schedule_expired,
                  :expiration_margin

    def initialize
      # if work is rescheduled after or before the worker completes
      self.reschedule_post_work = false

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
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration
      @configuration = Configuration.new
    end
  end
end
require 'rekiq/exceptions'
require 'rekiq/job'
require 'rekiq/scheduler'

module Rekiq
  module Worker
    class Configuration
      attr_accessor :shift, :schedule_post_work, :schedule_expired,
                    :expiration_margin, :addon, :canceller_args

      def rekiq_canceller_args(*args)
        self.canceller_args = args
      end
    end

    module ClassMethods
      attr_reader :canceller_name

      def rekiq_canceller(method_name)
        @canceller_name = method_name
      end

      def perform_recurringly(schedule, *args)
        @config = Configuration.new
        yield @config if block_given?

        validate!

        job =
          Rekiq::Job
            .new 'schedule'           => schedule,
                 'shift'              => @config.shift,
                 'schedule_post_work' => @config.schedule_post_work,
                 'schedule_expired'   => @config.schedule_expired,
                 'expiration_margin'  => @config.expiration_margin

        job.validate!

        queue = get_sidekiq_options['queue']

        jid, work_time =
          Rekiq::Scheduler
            .new(name, queue, args, job, @config.addon, @config.canceller_args)
            .schedule

        if jid.nil?
          return ::Sidekiq.logger.info \
                   "recurring work for #{name} scheduled for " \
                   "#{work_time} with jid #{jid}"
        end

        jid
      end

    protected

      def validate!
        unless canceller_name.nil? or
               self.method_defined?(canceller_name)
          raise CancellerMethodMissing,
                "rekiq_canceller method defined as #{canceller_name} " \
                'but worker does not have a method with that name, either ' \
                'remove rekiq_canceller or define missing method'
        end
      end
    end
  end
end

module Sidekiq
  module Worker
    attr_accessor :scheduled_work_time

    original_included_method = method(:included)

    define_singleton_method :included do |base|
      original_included_method.call(base)
      base.extend(Rekiq::Worker::ClassMethods)
    end

    def rekiq_canceller_name
      self.class.canceller_name
    end
  end
end
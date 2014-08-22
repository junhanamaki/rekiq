require 'rekiq/exceptions'
require 'rekiq/job'
require 'rekiq/scheduler'

module Rekiq
  module Worker
    class Configuration
      attr_accessor :shift, :schedule_post_work, :schedule_expired,
                    :expiration_margin, :addon, :cancel_args

      def rekiq_cancel_args(*args)
        @cancel_args = args
      end
    end

    module ClassMethods
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
            .new(name, queue, args, job, @config.addon, @config.cancel_args)
            .schedule

        if jid.nil?
          ::Sidekiq.logger.info \
            "recurring work for #{name} scheduled for " \
            "#{work_time} with jid #{jid}"
        end

        jid
      end

      def rekiq_cancel_method
        get_sidekiq_options['rekiq_cancel_method']
      end

    protected

      def validate!
        unless rekiq_cancel_method.nil? or
               self.method_defined?(rekiq_cancel_method)
          raise CancelMethodMissing,
                'rekiq cancel method name defined as '                         \
                "#{rekiq_cancel_method}, but worker does not have "            \
                'a method with that name, either remove definition or define ' \
                'missing method'
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

    def rekiq_cancel_method
      self.class.rekiq_cancel_method
    end
  end
end
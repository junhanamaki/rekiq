require 'rekiq/exceptions'
require 'rekiq/contract'
require 'rekiq/scheduler'

module Rekiq
  module Worker
    class Configuration
      attr_accessor :cancel_args, :addon, :schedule_post_work, :work_time_shift,
                    :work_time_tolerance, :schedule_expired

      def rekiq_cancel_args(*args)
        @cancel_args = args
      end
    end

    module ClassMethods
      def perform_recurringly(schedule, *args)
        @config = Configuration.new
        yield @config if block_given?

        contract =
          Rekiq::Contract
            .new 'schedule'            => schedule,
                 'addon'               => @config.addon,
                 'cancel_args'         => @config.cancel_args,
                 'schedule_post_work'  => @config.schedule_post_work,
                 'work_time_shift'     => @config.work_time_shift,
                 'work_time_tolerance' => @config.work_time_tolerance,
                 'schedule_expired'    => @config.schedule_expired

        contract.validate!

        queue = get_sidekiq_options['queue']

        jid, work_time =
          Rekiq::Scheduler.new(name, queue, args, contract).schedule

        unless jid.nil?
          ::Sidekiq.logger.info \
            "recurring work for #{name} scheduled for " \
            "#{work_time} with jid #{jid}"
        end

        jid
      end

      def rekiq_cancel_method
        get_sidekiq_options['rekiq_cancel_method']
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
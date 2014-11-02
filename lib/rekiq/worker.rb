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
                 'cancel_args'         => @config.cancel_args,
                 'addon'               => @config.addon,
                 'schedule_post_work'  => @config.schedule_post_work,
                 'work_time_shift'     => @config.work_time_shift,
                 'work_time_tolerance' => @config.work_time_tolerance,
                 'schedule_expired'    => @config.schedule_expired

        contract.validate!

        queue = get_sidekiq_options['queue']

        jid, work_time =
          Rekiq::Scheduler.new(self, queue, args, contract).schedule_work

        unless jid.nil?
          ::Sidekiq.logger.info \
            "recurring work for #{self.name} scheduled for #{work_time} " \
            "with jid #{jid}"
        end

        jid
      end

      def cancel_rekiq_worker?(method_args = nil)
        method_name = get_sidekiq_options['rekiq_cancel_method']

        !method_name.nil? and send(method_name, *method_args)
      rescue StandardError => s
        raise CancelMethodInvocationError,
              "error while invoking rekiq_cancel_method: #{s.message}",
              s.backtrace
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
  end
end
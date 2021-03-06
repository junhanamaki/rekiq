require 'rekiq/exceptions'
require 'rekiq/contract'
require 'rekiq/scheduler'

module Rekiq
  module Worker
    class Configuration
      attr_accessor :cancel_args, :addon, :schedule_post_work, :work_time_shift,
                    :work_time_tolerance, :schedule_expired, :starting_at

      def rekiq_cancel_args(*args)
        @cancel_args = args
      end
    end

    module ClassMethods
      def perform_recurringly(schedule, *args)
        validate!

        config = Configuration.new
        yield config if block_given?

        contract =
          Rekiq::Contract
            .new 'schedule'            => schedule,
                 'cancel_args'         => config.cancel_args,
                 'addon'               => config.addon,
                 'schedule_post_work'  => config.schedule_post_work,
                 'work_time_shift'     => config.work_time_shift,
                 'work_time_tolerance' => config.work_time_tolerance,
                 'schedule_expired'    => config.schedule_expired

        contract.validate!

        queue = get_sidekiq_options['queue']

        jid, work_time =
          Rekiq::Scheduler
            .new(self.name, queue, args, contract)
            .schedule_initial_work(config.starting_at || Time.now)

        unless jid.nil?
          ::Sidekiq.logger.info \
            "recurring work for #{self.name} scheduled for #{work_time} " \
            "with jid #{jid}"
        end

        jid
      end
      alias_method :perform_schedule, :perform_recurringly

    protected

      def validate!
        method_name = get_sidekiq_options['rekiq_cancel_method']

        unless method_name.nil? or method_defined?(method_name)
          raise ::Rekiq::CancelMethodMissing,
                "rekiq cancel method name defined as #{method_name}, but " \
                'worker has no method with that name, either remove '      \
                'definition or define missing method'
        end
      end
    end
  end
end

module Sidekiq
  module Worker
    attr_accessor :scheduled_work_time, :estimated_next_work_time

    original_included_method = method(:included)

    define_singleton_method :included do |base|
      original_included_method.call(base)
      base.extend(Rekiq::Worker::ClassMethods)
    end

    def cancel_rekiq_worker?(*method_args)
      method_name = self.class.get_sidekiq_options['rekiq_cancel_method']

      !method_name.nil? and send(method_name, *method_args)
    rescue StandardError => s
      raise ::Rekiq::CancelMethodInvocationError,
            "error while invoking rekiq_cancel_method: #{s.message}",
            s.backtrace
    end
  end
end
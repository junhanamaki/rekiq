require 'rekiq/exceptions'
require 'rekiq/job'
require 'rekiq/scheduler'

module Rekiq
  module Worker
    class Configuration
      attr_accessor :shift, :schedule_post_work, :schedule_expired,
                    :expiration_margin, :addon, :canceler_args

      def rekiq_canceler_args(*args)
        self.canceler_args = args
      end
    end

    module ClassMethods
      attr_reader :canceler_name

      def rekiq_canceler(method_name)
        @canceler_name = method_name
      end

      def perform_recurringly(schedule, *args)
        config = Configuration.new
        yield config if block_given?

        job =
          Rekiq::Job
            .new 'schedule'           => schedule,
                 'shift'              => config.shift,
                 'schedule_post_work' => config.schedule_post_work,
                 'schedule_expired'   => config.schedule_expired,
                 'expiration_margin'  => config.expiration_margin

        job.validate!

        queue = get_sidekiq_options['queue']

        jid, work_time =
          Rekiq::Scheduler
            .new(name, queue, args, job, config.addon, config.canceler_args)
            .schedule

        return if jid.nil?

        ::Sidekiq.logger.info "recurring work for #{name} scheduled for " \
                              "#{work_time} with jid #{jid}"

        jid
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
require 'rekiq/exceptions'
require 'rekiq/job'
require 'rekiq/scheduler'

module Rekiq
  module Worker
    class Configuration
      attr_accessor :shift, :reschedule_post_work, :schedule_expired,
                    :expiration_margin, :addon
    end

    module ClassMethods
      def perform_recurringly(schedule, *args)
        config = Configuration.new
        yield config if block_given?

        job =
          Rekiq::Job
            .new 'schedule'             => schedule,
                 'shift'                => config.shift,
                 'reschedule_post_work' => config.reschedule_post_work,
                 'schedule_expired'     => config.schedule_expired,
                 'expiration_margin'    => config.expiration_margin

        queue = get_sidekiq_options['queue']

        jid, work_time =
          Rekiq::Scheduler
            .new(name, queue, args, job, config.addon)
            .schedule

        return if jid.nil?

        ::Sidekiq.logger.info "recurring work for #{name} scheduled for " \
                              "#{work_time} with jid #{jid}"

        jid
      rescue StandardError => e
        raise Rekiq::StandardError,
              'unable to schedule worker',
              e.backtrace
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
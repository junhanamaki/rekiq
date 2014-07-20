require 'sidekiq'
require 'sidekiq/util'
require 'rekiq/configuration'
require 'rekiq/job'
require 'rekiq/scheduler'

module Rekiq
  module Middleware
    class WorkOverseer
      include ::Sidekiq::Util

      attr_accessor :worker_name, :queue, :args, :job, :addon,
                    :scheduled_work_time

      def call(worker, msg, queue)
        return yield unless msg['rq:job'] and msg['retry_count'].nil?

        self.worker_name = worker.class.name
        self.queue       = queue
        self.args        = msg['args']
        self.job         = Job.from_array(msg['rq:job'])
        self.addon       = msg['rq:addon']
        self.scheduled_work_time = Time.at(msg['rq:at'].to_f)

        begin
          reschedule unless job.schedule_post_work?
          yield
        ensure
          reschedule if job.schedule_post_work?
        end
      end

      def reschedule
        jid, work_time =
          Rekiq::Scheduler
            .new(worker_name, queue, args, job, addon)
            .schedule_from_work_time(scheduled_work_time)

        unless jid.nil?
          logger.info "recurring work for #{worker_name} scheduled for " \
                      "#{work_time} with jid #{jid}"
        else
          logger.info 'recurrence terminated, job terminated'
        end
      end
    end
  end
end